# -*- coding: utf-8 -*-
"""
AIGirl Backend (local/offline)

Single-file backend used by both:
  - C:\\AIGirl\\backend\\app.py
  - C:\\AIGirl\\backend\\main.py

Key features:
  - FastAPI HTTP API (local)
  - MS SQL Server storage via pyodbc
  - Interaction events storage (dbo.InteractionEvents)
  - Autotune engine using dbo.ParameterAutoTunePolicy + accumulators
  - Optional background autotune worker
  - Local debug endpoints

IMPORTANT:
  - Do not hardcode secrets in this file. Use backend/.env or service environment variables.
"""

from __future__ import annotations

import json
import logging
import os
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import pyodbc
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field

APP_VERSION = "0.3.1-patch002-hf1"
DEFAULT_CHARKEY = "default"


# -----------------------------
# Environment (.env + process env)
# -----------------------------
BACKEND_DIR = Path(__file__).resolve().parent

# Load backend/.env reliably even when service working directory is different.
load_dotenv(BACKEND_DIR / ".env", override=False)
# Optionally also load root .env (C:\AIGirl\.env) if exists.
load_dotenv(BACKEND_DIR.parent / ".env", override=False)


def _env(key: str, default: Optional[str] = None) -> Optional[str]:
    v = os.getenv(key)
    if v is None or v == "":
        return default
    return v


def _env_bool(key: str, default: bool = False) -> bool:
    v = _env(key)
    if v is None:
        return default
    return str(v).strip().lower() in {"1", "true", "yes", "y", "on"}


def _env_int(key: str, default: int) -> int:
    v = _env(key)
    if v is None:
        return default
    try:
        return int(float(v))
    except Exception:
        return default


# -----------------------------
# Logging
# -----------------------------
ROOT_DEFAULT = Path(r"C:\AIGirl")
ROOT = Path(_env("AIGIRL_ROOT", str(BACKEND_DIR.parent)) or str(BACKEND_DIR.parent))  # default: C:\AIGirl
if not ROOT.exists():
    ROOT = ROOT_DEFAULT

LOG_DIR = ROOT / "logs"
LOG_FILE = LOG_DIR / "backend_api.log"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    handlers=[
        logging.FileHandler(str(LOG_FILE), encoding="utf-8"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger("aigirl-backend")

# Disable pyodbc connection pooling for more deterministic behavior in Windows services.
# (Optional; set PYODBC_POOLING=1 to re-enable.)
pyodbc.pooling = _env_bool("PYODBC_POOLING", default=False)


# -----------------------------
# DB connection
# -----------------------------
def _db_get(key: str, alt_key: str, default: Optional[str] = None) -> Optional[str]:
    return _env(key) or _env(alt_key) or default


def _available_drivers() -> List[str]:
    try:
        return list(pyodbc.drivers())
    except Exception:
        return []


def _drivers_to_try() -> List[str]:
    """
    Driver selection strategy:
      1) If DB_DRIVER is set and present -> first.
      2) Else prefer 18 then 17 if present.
      3) Else fall back to any installed driver containing "ODBC Driver".
    """
    installed = _available_drivers()
    pref = _env("DB_DRIVER")
    out: List[str] = []

    if pref and pref in installed:
        out.append(pref)

    for d in ("ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server"):
        if d in installed and d not in out:
            out.append(d)

    if not out:
        for d in installed:
            if "ODBC Driver" in d and d not in out:
                out.append(d)

    if not out:
        out = installed[:]
    return out


def _build_cs_sql(driver: str, server: str, database: str, user: str, pwd: str) -> str:
    encrypt = _env("DB_ENCRYPT", "yes")
    trust = _env("DB_TRUST_CERT", "yes")
    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={user};"
        f"PWD={pwd};"
        f"Encrypt={encrypt};"
        f"TrustServerCertificate={trust};"
    )


def _build_cs_integrated(driver: str, server: str, database: str) -> str:
    encrypt = _env("DB_ENCRYPT", "yes")
    trust = _env("DB_TRUST_CERT", "yes")
    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
        f"Encrypt={encrypt};"
        f"TrustServerCertificate={trust};"
    )


def get_cnx(autocommit: bool = False) -> pyodbc.Connection:
    """
    Supported env (preferred):
      DB_SERVER, DB_NAME, DB_USER, DB_PASSWORD, DB_DRIVER

    Supported env (fallback):
      AIGIRL_SQL_SERVER, AIGIRL_SQL_DB, AIGIRL_SQL_USER, AIGIRL_SQL_PASSWORD
    """
    server = _db_get("DB_SERVER", "AIGIRL_SQL_SERVER")
    database = _db_get("DB_NAME", "AIGIRL_SQL_DB", "AIGirl") or "AIGirl"
    user = _db_get("DB_USER", "AIGIRL_SQL_USER")
    pwd = _db_get("DB_PASSWORD", "AIGIRL_SQL_PASSWORD") or ""
    timeout = _env_int("DB_TIMEOUT_SEC", 5)

    if not server:
        raise RuntimeError("DB_SERVER is not set (backend/.env or service env).")

    allow_fallback_integrated = _env_bool("DB_FALLBACK_INTEGRATED", default=False)

    last_err: Optional[Exception] = None
    for drv in _drivers_to_try():
        if user and pwd:
            try:
                cs = _build_cs_sql(drv, server, database, user, pwd)
                return pyodbc.connect(cs, autocommit=autocommit, timeout=timeout)
            except Exception as e:
                last_err = e
                if not allow_fallback_integrated:
                    break

        try:
            cs = _build_cs_integrated(drv, server, database)
            return pyodbc.connect(cs, autocommit=autocommit, timeout=timeout)
        except Exception as e:
            last_err = e
            continue

    raise RuntimeError(f"Cannot connect to SQL Server via ODBC. Last error: {last_err!r}") from last_err


# -----------------------------
# FastAPI app
# -----------------------------
app = FastAPI(title="AIGirl Backend", version=APP_VERSION)


@app.middleware("http")
async def force_utf8_json_charset(request, call_next):
    response = await call_next(request)
    ct = response.headers.get("content-type", "")
    if ct.startswith("application/json") and "charset=" not in ct.lower():
        response.headers["content-type"] = "application/json; charset=utf-8"
    return response


# -----------------------------
# Models
# -----------------------------
class TraitSetIn(BaseModel):
    parameter_key: str = Field(..., min_length=1)
    value_int: int
    reason_ru: str = "Ручная настройка"
    source: str = "admin"


class ThoughtTemplateUpsertIn(BaseModel):
    character_key: Optional[str] = None  # None -> default
    bin_min: int
    bin_max: int
    text_ru: str
    trend_up_text_ru: Optional[str] = None
    trend_down_text_ru: Optional[str] = None


class EventIn(BaseModel):
    platform: str = "admin"
    channel: str = "dm"
    conversation_key: Optional[str] = None
    character_key: str
    event_type: str
    lang: Optional[str] = None
    text: Optional[str] = None
    sentiment: Optional[float] = None
    engagement: Optional[float] = None
    admin_score: Optional[int] = None
    payload: Optional[Dict[str, Any]] = None


class ProcessResult(BaseModel):
    ok: bool
    processed_events: int
    applied_changes: int
    dry_run: bool
    notes: Optional[str] = None


class PolicySetIn(BaseModel):
    parameter_key: str
    enabled: Optional[bool] = None
    min_allowed: Optional[int] = None
    max_allowed: Optional[int] = None
    learn_rate: Optional[float] = None
    signals: Optional[Dict[str, Any]] = None


# -----------------------------
# Helpers
# -----------------------------
def _parse_json_safe(s: Optional[str]) -> Optional[Dict[str, Any]]:
    if not s:
        return None
    try:
        return json.loads(s)
    except Exception:
        return None


def _now_iso() -> str:
    return datetime.utcnow().isoformat() + "Z"


def _clamp_int(v: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, v))


def _fetch_first_row_anyset(cur) -> Optional[Tuple[Any, ...]]:
    """
    Some SQL Server/ODBC combinations can produce empty first result sets
    (e.g., due to triggers/NOCOUNT). This helper scans nextsets.
    """
    try:
        row = cur.fetchone()
    except Exception:
        row = None
    while row is None:
        try:
            has_next = cur.nextset()
        except Exception:
            has_next = False
        if not has_next:
            break
        try:
            row = cur.fetchone()
        except Exception:
            row = None
    return tuple(row) if row is not None else None


def _fetch_first_scalar_anyset(cur) -> Optional[Any]:
    row = _fetch_first_row_anyset(cur)
    if not row:
        return None
    return row[0]


def _get_character_id(cursor, character_key: str) -> int:
    cursor.execute("SELECT TOP 1 Id FROM dbo.Characters WHERE [Key]=?", character_key)
    row = cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail=f"Character '{character_key}' not found")
    return int(row[0])


def _get_last_delta(cursor, character_id: int, parameter_key: str) -> int:
    cursor.execute(
        "SELECT TOP 1 COALESCE(DeltaInt,0) FROM dbo.CharacterParameterHistory "
        "WHERE CharacterId=? AND ParameterKey=? ORDER BY CreatedAt DESC, Id DESC",
        character_id,
        parameter_key,
    )
    row = cursor.fetchone()
    return int(row[0]) if row else 0


def _get_thought(cursor, parameter_key: str, character_key: str, value_int: int, trend_delta: int) -> Optional[str]:
    cursor.execute(
        "SELECT TOP 1 TextRu, TrendUpTextRu, TrendDownTextRu "
        "FROM dbo.ParameterThoughtTemplates "
        "WHERE ParameterKey=? AND CharacterKey=? AND BinMin<=? AND BinMax>=? "
        "ORDER BY BinMin ASC",
        parameter_key,
        character_key,
        value_int,
        value_int,
    )
    row = cursor.fetchone()
    if not row:
        cursor.execute(
            "SELECT TOP 1 TextRu, TrendUpTextRu, TrendDownTextRu "
            "FROM dbo.ParameterThoughtTemplates "
            "WHERE ParameterKey=? AND CharacterKey=? AND BinMin<=? AND BinMax>=? "
            "ORDER BY BinMin ASC",
            parameter_key,
            DEFAULT_CHARKEY,
            value_int,
            value_int,
        )
        row = cursor.fetchone()
    if not row:
        return None

    text = row[0]
    up = row[1] if len(row) > 1 else None
    down = row[2] if len(row) > 2 else None

    if trend_delta > 0 and up:
        return f"{text} {up}"
    if trend_delta < 0 and down:
        return f"{text} {down}"
    return text


def _ensure_value_row(cursor, character_id: int, parameter_key: str) -> int:
    cursor.execute(
        "SELECT ValueInt FROM dbo.CharacterParameterValues WHERE CharacterId=? AND ParameterKey=?",
        character_id,
        parameter_key,
    )
    row = cursor.fetchone()
    if row and row[0] is not None:
        return int(row[0])

    cursor.execute("SELECT TOP 1 DefaultValue FROM dbo.ParameterDefinitions WHERE [Key]=?", parameter_key)
    d = cursor.fetchone()
    default_value = int(d[0]) if d and d[0] is not None else 50

    cursor.execute(
        "MERGE dbo.CharacterParameterValues AS tgt "
        "USING (SELECT ? AS CharacterId, ? AS ParameterKey) AS src "
        "ON (tgt.CharacterId=src.CharacterId AND tgt.ParameterKey=src.ParameterKey) "
        "WHEN MATCHED THEN UPDATE SET ValueInt=?, UpdatedAt=sysdatetime() "
        "WHEN NOT MATCHED THEN INSERT(CharacterId,ParameterKey,ValueInt,UpdatedAt) VALUES(?,?,?,sysdatetime());",
        character_id,
        parameter_key,
        default_value,
        character_id,
        parameter_key,
        default_value,
    )
    return default_value


def _set_value(cursor, character_id: int, parameter_key: str, new_value: int, reason_ru: str, source: str) -> Tuple[int, int]:
    old_value = _ensure_value_row(cursor, character_id, parameter_key)

    cursor.execute(
        "SELECT TOP 1 MinAllowed, MaxAllowed FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey=?",
        parameter_key,
    )
    pol = cursor.fetchone()
    if pol and pol[0] is not None and pol[1] is not None:
        min_allowed, max_allowed = int(pol[0]), int(pol[1])
    else:
        cursor.execute("SELECT TOP 1 MinValue, MaxValue FROM dbo.ParameterDefinitions WHERE [Key]=?", parameter_key)
        d = cursor.fetchone()
        min_allowed, max_allowed = (int(d[0]), int(d[1])) if d else (0, 100)

    clamped = _clamp_int(int(new_value), min_allowed, max_allowed)
    delta = clamped - old_value

    cursor.execute(
        "UPDATE dbo.CharacterParameterValues SET ValueInt=?, UpdatedAt=sysdatetime() "
        "WHERE CharacterId=? AND ParameterKey=?",
        clamped,
        character_id,
        parameter_key,
    )
    cursor.execute(
        "INSERT INTO dbo.CharacterParameterHistory(CharacterId,ParameterKey,OldValueInt,NewValueInt,DeltaInt,ReasonRu,Source) "
        "VALUES(?,?,?,?,?,?,?)",
        character_id,
        parameter_key,
        old_value,
        clamped,
        delta,
        reason_ru,
        source,
    )
    return old_value, clamped


# -----------------------------
# Autotune engine
# -----------------------------
AUTOTUNE_BACKGROUND = _env_bool("AUTOTUNE_BACKGROUND", default=False)
AUTOTUNE_INTERVAL_SEC = _env_int("AUTOTUNE_INTERVAL_SEC", 30)
AUTOTUNE_MAX_EVENTS = _env_int("AUTOTUNE_MAX_EVENTS", 50)


def _normalize_signal(name: str, v: Optional[float]) -> float:
    if v is None:
        return 0.0
    try:
        x = float(v)
    except Exception:
        return 0.0

    if name == "admin_score":
        x = float(_clamp_int(int(round(x)), 1, 5))
        return (x - 3.0) / 2.0

    if name == "engagement":
        if x < 0.0:
            x = 0.0
        if x > 1.0:
            x = 1.0
        return x * 2.0 - 1.0

    if name == "sentiment":
        if x < -1.0:
            x = -1.0
        if x > 1.0:
            x = 1.0
        return x

    if x < -1.0:
        x = -1.0
    if x > 1.0:
        x = 1.0
    return x


def _get_policy(cursor, parameter_key: str) -> Tuple[bool, int, int, float, Dict[str, Any]]:
    cursor.execute(
        "SELECT Enabled, MinAllowed, MaxAllowed, LearnRate, COALESCE(SignalsJson,N'{}') "
        "FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey=?",
        parameter_key,
    )
    row = cursor.fetchone()
    if not row:
        return False, 0, 100, 0.0, {}
    enabled = bool(row[0])
    min_allowed = int(row[1]) if row[1] is not None else 0
    max_allowed = int(row[2]) if row[2] is not None else 100
    learn_rate = float(row[3]) if row[3] is not None else 0.0
    sig = _parse_json_safe(row[4]) or {}
    return enabled, min_allowed, max_allowed, learn_rate, sig


def _get_accumulator(cursor, character_id: int, parameter_key: str) -> float:
    cursor.execute(
        "SELECT Residual FROM dbo.CharacterParameterAccumulators WHERE CharacterId=? AND ParameterKey=?",
        character_id,
        parameter_key,
    )
    row = cursor.fetchone()
    return float(row[0]) if row and row[0] is not None else 0.0


def _set_accumulator(cursor, character_id: int, parameter_key: str, residual: float) -> None:
    cursor.execute(
        "MERGE dbo.CharacterParameterAccumulators AS tgt "
        "USING (SELECT ? AS CharacterId, ? AS ParameterKey) AS src "
        "ON (tgt.CharacterId=src.CharacterId AND tgt.ParameterKey=src.ParameterKey) "
        "WHEN MATCHED THEN UPDATE SET Residual=? "
        "WHEN NOT MATCHED THEN INSERT(CharacterId,ParameterKey,Residual) VALUES(?,?,?);",
        character_id,
        parameter_key,
        float(residual),
        character_id,
        parameter_key,
        float(residual),
    )


def _compute_delta_from_signals(learn_rate: float, weights: Dict[str, Any], signals: Dict[str, float]) -> float:
    s = 0.0
    for k, w in (weights or {}).items():
        if str(k).startswith("__"):
            continue
        try:
            wf = float(w)
        except Exception:
            continue
        s += wf * float(signals.get(str(k), 0.0))
    return float(learn_rate) * s


def _apply_autotune_delta(
    cursor,
    character_id: int,
    parameter_key: str,
    delta_float: float,
    reason_ru: str,
    source: str,
    dry_run: bool,
) -> int:
    enabled, min_allowed, max_allowed, _, _ = _get_policy(cursor, parameter_key)
    if not enabled:
        return 0

    residual = _get_accumulator(cursor, character_id, parameter_key)
    residual_new = residual + float(delta_float)

    delta_int = 0
    if residual_new >= 1.0:
        delta_int = int(residual_new // 1.0)
        residual_new -= float(delta_int)
    elif residual_new <= -1.0:
        delta_int = -int((-residual_new) // 1.0)
        residual_new -= float(delta_int)

    if dry_run:
        return int(delta_int)

    _set_accumulator(cursor, character_id, parameter_key, residual_new)

    if delta_int == 0:
        return 0

    old_value = _ensure_value_row(cursor, character_id, parameter_key)
    new_value = _clamp_int(old_value + int(delta_int), min_allowed, max_allowed)
    applied = new_value - old_value

    if applied == 0:
        return 0

    cursor.execute(
        "UPDATE dbo.CharacterParameterValues SET ValueInt=?, UpdatedAt=sysdatetime() "
        "WHERE CharacterId=? AND ParameterKey=?",
        new_value,
        character_id,
        parameter_key,
    )
    cursor.execute(
        "INSERT INTO dbo.CharacterParameterHistory(CharacterId,ParameterKey,OldValueInt,NewValueInt,DeltaInt,ReasonRu,Source) "
        "VALUES(?,?,?,?,?,?,?)",
        character_id,
        parameter_key,
        old_value,
        new_value,
        applied,
        reason_ru,
        source,
    )
    return int(applied)


def _event_category(event_type: str) -> str:
    t = (event_type or "").lower()
    if t.startswith("admin"):
        return "admin"
    if "metric" in t or "reaction" in t or "like" in t or "view" in t:
        return "public"
    if "inbound" in t or "comment" in t or "dm_in" in t or "message_in" in t:
        return "inbound"
    return "generic"


def _candidate_keys_for_category(cat: str) -> List[str]:
    if cat == "inbound":
        return [
            "state.mood", "state.energy", "state.stress", "state.calm",
            "state.curiosity", "state.irritation", "state.playfulness",
            "state.social_battery", "state.loneliness",
            "trait.social.empathy", "trait.social.boundaries",
        ]
    if cat == "public":
        return [
            "state.satisfaction", "state.confidence", "state.inspiration",
            "trait.core.self_confidence", "trait.core.optimism",
            "voice.confidence", "voice.warmth",
            "trait.speech.storytelling", "trait.speech.humor",
        ]
    if cat == "admin":
        return [
            "trait.core.self_confidence", "trait.core.orderliness", "trait.core.optimism",
            "trait.core.anxiety", "trait.core.emotional_stability",
            "trait.social.empathy", "trait.social.tact", "trait.social.boundaries", "trait.social.supportiveness",
            "trait.speech.storytelling", "trait.speech.humor", "trait.speech.verbosity", "trait.speech.confidence_tone",
            "voice.confidence", "voice.warmth", "voice.emotion_variation",
            "state.confidence", "state.satisfaction",
        ]
    return ["state.mood", "state.energy", "state.stress", "state.confidence", "state.satisfaction"]


def autotune_process_events(limit: int = 100, dry_run: bool = False, character_key: Optional[str] = None) -> Tuple[int, int]:
    processed = 0
    applied = 0

    with get_cnx(autocommit=False) as cn:
        cur = cn.cursor()

        if character_key:
            cur.execute(
                "SELECT TOP (?) Id, CharacterKey, EventType, Lang, Sentiment, EngagementScore, AdminScore, PayloadJson "
                "FROM dbo.InteractionEvents WHERE Processed=0 AND CharacterKey=? ORDER BY CreatedAt ASC, Id ASC",
                int(limit),
                character_key,
            )
        else:
            cur.execute(
                "SELECT TOP (?) Id, CharacterKey, EventType, Lang, Sentiment, EngagementScore, AdminScore, PayloadJson "
                "FROM dbo.InteractionEvents WHERE Processed=0 ORDER BY CreatedAt ASC, Id ASC",
                int(limit),
            )

        rows = cur.fetchall()

        for r in rows:
            event_id = int(r[0])
            ch_key = str(r[1])
            ev_type = str(r[2] or "")

            sentiment = r[4]
            engagement = r[5]
            admin_score = r[6]

            cat = _event_category(ev_type)
            candidate_keys = _candidate_keys_for_category(cat)

            signals = {
                "sentiment": _normalize_signal("sentiment", sentiment),
                "engagement": _normalize_signal("engagement", engagement),
                "admin_score": _normalize_signal("admin_score", admin_score),
            }

            try:
                char_id = _get_character_id(cur, ch_key)
            except HTTPException:
                if not dry_run:
                    cur.execute(
                        "UPDATE dbo.InteractionEvents SET Processed=1, ProcessedAt=sysdatetime(), ProcessingNotes=? WHERE Id=?",
                        "character_not_found",
                        event_id,
                    )
                processed += 1
                continue

            change_count = 0
            for pkey in candidate_keys:
                enabled, _, _, learn_rate, weights = _get_policy(cur, pkey)
                if not enabled:
                    continue
                if not weights:
                    continue

                delta_float = _compute_delta_from_signals(learn_rate, weights, signals)
                if abs(delta_float) < 1e-9:
                    continue

                reason = f"autotune({cat}): {ev_type} signals={json.dumps(signals, ensure_ascii=False)}"
                d_int = _apply_autotune_delta(cur, char_id, pkey, delta_float, reason, "autotune", dry_run=dry_run)
                if d_int != 0:
                    applied += 1
                    change_count += 1

            if not dry_run:
                cur.execute(
                    "UPDATE dbo.InteractionEvents SET Processed=1, ProcessedAt=sysdatetime(), ProcessingNotes=? WHERE Id=?",
                    f"cat={cat}; changes={change_count}",
                    event_id,
                )

            processed += 1

        if dry_run:
            cn.rollback()
        else:
            cn.commit()

    return processed, applied


def _log_autotune_run(processed_events: int, applied_changes: int, dry_run: bool, notes: str = "") -> None:
    try:
        with get_cnx(autocommit=False) as cn:
            cur = cn.cursor()
            cur.execute(
                "INSERT INTO dbo.AutotuneRuns(ProcessedEvents,AppliedChanges,DryRun,Notes,CompletedAt) "
                "VALUES(?,?,?,?,sysdatetime())",
                int(processed_events),
                int(applied_changes),
                1 if dry_run else 0,
                notes,
            )
            cn.commit()
    except Exception as e:
        logger.warning("Failed to log autotune run: %s", str(e))


def _autotune_loop() -> None:
    time.sleep(2.0)
    while True:
        try:
            p, a = autotune_process_events(limit=AUTOTUNE_MAX_EVENTS, dry_run=False)
            if p > 0:
                _log_autotune_run(p, a, dry_run=False, notes="background")
                logger.info("Autotune background: processed=%s applied=%s", p, a)
        except Exception as e:
            logger.exception("Autotune background error: %s", str(e))
        time.sleep(max(5, AUTOTUNE_INTERVAL_SEC))


# -----------------------------
# Routes: Debug
# -----------------------------
@app.get("/health")
def health() -> Dict[str, Any]:
    return {"ok": True, "version": APP_VERSION, "ts": _now_iso()}


@app.get("/debug/dbtest")
def debug_dbtest() -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        cur.execute("SELECT @@VERSION")
        ver = cur.fetchone()[0]
        return {"ok": True, "db": {"SqlVersion": ver}}


@app.get("/debug/whoami")
def debug_whoami() -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        cur.execute("SELECT ORIGINAL_LOGIN() AS original_login, SUSER_SNAME() AS suser_sname")
        row = cur.fetchone()
        return {"ok": True, "original_login": row[0], "suser_sname": row[1]}


@app.get("/debug/routes")
def debug_routes() -> Dict[str, Any]:
    routes = []
    for r in app.router.routes:
        path = getattr(r, "path", None)
        methods = sorted(list(getattr(r, "methods", []) or []))
        name = getattr(r, "name", None)
        if path:
            routes.append({"path": path, "methods": methods, "name": name})
    routes = sorted(routes, key=lambda x: x.get("path", ""))
    return {"ok": True, "count": len(routes), "routes": routes}


@app.get("/debug/log_tail")
def debug_log_tail(lines: int = 200) -> Dict[str, Any]:
    try:
        n = int(lines)
    except Exception:
        n = 200
    n = 50 if n < 50 else (2000 if n > 2000 else n)

    if not LOG_FILE.exists():
        return {"ok": True, "log_file": str(LOG_FILE), "lines": []}

    txt = LOG_FILE.read_text(encoding="utf-8", errors="replace").splitlines()
    return {"ok": True, "log_file": str(LOG_FILE), "lines": txt[-n:]}


# -----------------------------
# Routes: Characters / Parameters / Traits
# -----------------------------
@app.get("/characters")
def get_characters() -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        cur.execute(
            "SELECT [Key], DisplayName, Surname, [Name], DistinctiveMarksJson, NotesRu "
            "FROM dbo.Characters ORDER BY Id ASC"
        )
        res = []
        for r in cur.fetchall():
            dmj = r[4]
            res.append(
                {
                    "Key": r[0],
                    "DisplayName": r[1],
                    "Surname": r[2],
                    "Name": r[3],
                    "DistinctiveMarksJson": dmj,
                    "NotesRu": r[5],
                    "DistinctiveMarks": _parse_json_safe(dmj),
                }
            )
        return {"value": res, "Count": len(res)}


@app.get("/parameters")
def get_parameters(prefix: str = Query("", description="Filter by prefix, e.g. trait.")) -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        if prefix:
            cur.execute(
                "SELECT [Key], NameRu, GroupRu, MinValue, MaxValue, DefaultValue, HintRu, ValueType, UnitRu, StepValue "
                "FROM dbo.ParameterDefinitions WHERE [Key] LIKE ? ORDER BY GroupRu, NameRu",
                prefix + "%",
            )
        else:
            cur.execute(
                "SELECT [Key], NameRu, GroupRu, MinValue, MaxValue, DefaultValue, HintRu, ValueType, UnitRu, StepValue "
                "FROM dbo.ParameterDefinitions ORDER BY GroupRu, NameRu"
            )
        rows = cur.fetchall()
        out = []
        for r in rows:
            out.append(
                {
                    "key": r[0],
                    "nameRu": r[1],
                    "groupRu": r[2],
                    "minValue": int(r[3]),
                    "maxValue": int(r[4]),
                    "defaultValue": int(r[5]) if r[5] is not None else 50,
                    "hintRu": r[6],
                    "valueType": r[7],
                    "unitRu": r[8],
                    "stepValue": r[9],
                }
            )
        return {"value": out, "Count": len(out)}


@app.get("/characters/{character_key}/traits")
def get_character_traits(character_key: str) -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        char_id = _get_character_id(cur, character_key)

        cur.execute(
            "SELECT [Key], NameRu, GroupRu, MinValue, MaxValue, DefaultValue, HintRu, ValueType, UnitRu, StepValue "
            "FROM dbo.ParameterDefinitions "
            "WHERE [Key] LIKE N'trait.%' OR [Key] LIKE N'state.%' OR [Key] LIKE N'voice.%' "
            "ORDER BY GroupRu, NameRu"
        )
        defs = cur.fetchall()

        out = []
        for d in defs:
            pkey = d[0]
            value = _ensure_value_row(cur, char_id, pkey)
            trend = _get_last_delta(cur, char_id, pkey)
            thought = _get_thought(cur, pkey, character_key, value, trend)
            out.append(
                {
                    "key": pkey,
                    "nameRu": d[1],
                    "groupRu": d[2],
                    "minValue": int(d[3]),
                    "maxValue": int(d[4]),
                    "defaultValue": int(d[5]) if d[5] is not None else 50,
                    "hintRu": d[6],
                    "valueType": d[7],
                    "unitRu": d[8],
                    "stepValue": d[9],
                    "valueInt": int(value),
                    "thoughtRu": thought,
                    "trendDelta": int(trend),
                }
            )
        return {"value": out, "Count": len(out)}


@app.post("/characters/{character_key}/traits/set")
def set_character_trait(character_key: str, payload: TraitSetIn) -> Dict[str, Any]:
    if payload.value_int < -100000 or payload.value_int > 100000:
        raise HTTPException(status_code=400, detail="value_int out of allowed range")

    with get_cnx(autocommit=False) as cn:
        cur = cn.cursor()
        char_id = _get_character_id(cur, character_key)

        cur.execute(
            "DELETE FROM dbo.CharacterParameterAccumulators WHERE CharacterId=? AND ParameterKey=?",
            char_id,
            payload.parameter_key,
        )

        old_v, new_v = _set_value(cur, char_id, payload.parameter_key, int(payload.value_int), payload.reason_ru, payload.source)
        cn.commit()

    return {"ok": True, "parameter_key": payload.parameter_key, "old": old_v, "new": new_v}


@app.get("/characters/{character_key}/traits/history")
def get_trait_history(character_key: str, parameter_key: str, limit: int = 50) -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        char_id = _get_character_id(cur, character_key)

        lim = int(limit)
        if lim < 1:
            lim = 1
        if lim > 500:
            lim = 500

        cur.execute(
            "SELECT TOP (?) OldValueInt, NewValueInt, DeltaInt, ReasonRu, Source, CreatedAt "
            "FROM dbo.CharacterParameterHistory "
            "WHERE CharacterId=? AND ParameterKey=? "
            "ORDER BY CreatedAt DESC, Id DESC",
            lim,
            char_id,
            parameter_key,
        )

        rows = cur.fetchall()
        out = []
        for r in rows:
            out.append(
                {
                    "old": r[0],
                    "new": r[1],
                    "delta": r[2],
                    "reasonRu": r[3],
                    "source": r[4],
                    "createdAt": r[5].isoformat() if r[5] else None,
                }
            )
        return {"ok": True, "value": out, "Count": len(out)}


# -----------------------------
# Routes: Thought templates
# -----------------------------
@app.get("/thought_templates/{parameter_key}")
def get_thought_templates(parameter_key: str) -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        cur.execute(
            "SELECT ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu, UpdatedAt "
            "FROM dbo.ParameterThoughtTemplates WHERE ParameterKey=? "
            "ORDER BY CharacterKey, BinMin",
            parameter_key,
        )
        rows = cur.fetchall()
        out = []
        for r in rows:
            out.append(
                {
                    "parameter_key": r[0],
                    "character_key": r[1],
                    "bin_min": int(r[2]),
                    "bin_max": int(r[3]),
                    "text_ru": r[4],
                    "trend_up_text_ru": r[5],
                    "trend_down_text_ru": r[6],
                    "updated_at": r[7].isoformat() if r[7] else None,
                }
            )
        return {"ok": True, "value": out, "Count": len(out)}


@app.post("/thought_templates/{parameter_key}/upsert")
def upsert_thought_template(parameter_key: str, payload: ThoughtTemplateUpsertIn) -> Dict[str, Any]:
    ch_key = (payload.character_key or DEFAULT_CHARKEY).strip() or DEFAULT_CHARKEY

    with get_cnx(autocommit=False) as cn:
        cur = cn.cursor()
        cur.execute(
            "MERGE dbo.ParameterThoughtTemplates AS tgt "
            "USING (SELECT ? AS ParameterKey, ? AS CharacterKey, ? AS BinMin, ? AS BinMax) AS src "
            "ON (tgt.ParameterKey=src.ParameterKey AND tgt.CharacterKey=src.CharacterKey AND tgt.BinMin=src.BinMin AND tgt.BinMax=src.BinMax) "
            "WHEN MATCHED THEN UPDATE SET TextRu=?, TrendUpTextRu=?, TrendDownTextRu=?, UpdatedAt=sysdatetime() "
            "WHEN NOT MATCHED THEN INSERT(ParameterKey,CharacterKey,BinMin,BinMax,TextRu,TrendUpTextRu,TrendDownTextRu,UpdatedAt) "
            "VALUES(?,?,?,?,?,?,?,sysdatetime());",
            parameter_key,
            ch_key,
            int(payload.bin_min),
            int(payload.bin_max),
            payload.text_ru,
            payload.trend_up_text_ru,
            payload.trend_down_text_ru,
            parameter_key,
            ch_key,
            int(payload.bin_min),
            int(payload.bin_max),
            payload.text_ru,
            payload.trend_up_text_ru,
            payload.trend_down_text_ru,
        )
        cn.commit()

    return {"ok": True}


# -----------------------------
# Routes: Events + Autotune
# -----------------------------
@app.post("/events")
def create_event(payload: EventIn) -> Dict[str, Any]:
    """
    Store raw interaction event in dbo.InteractionEvents.

    Fix:
      - Use INSERT ... OUTPUT into table variable.
      - If OUTPUT returns NULL/empty (e.g. INSTEAD OF trigger) -> fallback to @@IDENTITY.
    """
    if not payload.character_key:
        raise HTTPException(status_code=400, detail="character_key required")

    conv_key = payload.conversation_key or f"{payload.platform}:{payload.channel}:{payload.character_key}"

    packed = dict(payload.payload or {})
    if payload.text is not None:
        packed["text"] = payload.text
    packed.update(
        {
            "platform": payload.platform,
            "channel": payload.channel,
            "event_type": payload.event_type,
            "conversation_key": conv_key,
            "lang": payload.lang,
        }
    )

    sql = """
    SET NOCOUNT ON;
    DECLARE @ids TABLE (Id bigint NULL);

    INSERT INTO dbo.InteractionEvents(
        Platform, Channel, ConversationKey, CharacterKey, EventType,
        PayloadJson, Lang, Sentiment, EngagementScore, AdminScore
    )
    OUTPUT CONVERT(bigint, INSERTED.Id) INTO @ids(Id)
    VALUES (?,?,?,?,?,?,?,?,?,?);

    SELECT TOP 1 Id FROM @ids;
    """

    params = (
        payload.platform,
        payload.channel,
        conv_key,
        payload.character_key,
        payload.event_type,
        json.dumps(packed, ensure_ascii=False),
        payload.lang,
        payload.sentiment,
        payload.engagement,
        payload.admin_score,
    )

    try:
        with get_cnx(autocommit=False) as cn:
            cur = cn.cursor()

            _ = _get_character_id(cur, payload.character_key)

            cur.execute(sql, params)
            eid = _fetch_first_scalar_anyset(cur)

            if eid is None:
                cur.execute("SELECT CONVERT(bigint, @@IDENTITY)")
                eid = _fetch_first_scalar_anyset(cur)

            cn.commit()

        return {"ok": True, "event_id": int(eid) if eid is not None else None}
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("create_event failed: %s", str(e))
        raise HTTPException(status_code=500, detail=f"create_event failed: {e}")


@app.get("/events/unprocessed")
def list_unprocessed_events(limit: int = 50, character_key: Optional[str] = None) -> Dict[str, Any]:
    lim = int(limit)
    lim = 1 if lim < 1 else (500 if lim > 500 else lim)

    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        if character_key:
            cur.execute(
                "SELECT TOP (?) Id, CreatedAt, Platform, Channel, ConversationKey, CharacterKey, EventType, Lang, Sentiment, EngagementScore, AdminScore "
                "FROM dbo.InteractionEvents WHERE Processed=0 AND CharacterKey=? ORDER BY CreatedAt ASC, Id ASC",
                lim,
                character_key,
            )
        else:
            cur.execute(
                "SELECT TOP (?) Id, CreatedAt, Platform, Channel, ConversationKey, CharacterKey, EventType, Lang, Sentiment, EngagementScore, AdminScore "
                "FROM dbo.InteractionEvents WHERE Processed=0 ORDER BY CreatedAt ASC, Id ASC",
                lim,
            )

        rows = cur.fetchall()
        out = []
        for r in rows:
            out.append(
                {
                    "id": int(r[0]),
                    "createdAt": r[1].isoformat() if r[1] else None,
                    "platform": r[2],
                    "channel": r[3],
                    "conversation_key": r[4],
                    "character_key": r[5],
                    "event_type": r[6],
                    "lang": r[7],
                    "sentiment": float(r[8]) if r[8] is not None else None,
                    "engagement": float(r[9]) if r[9] is not None else None,
                    "admin_score": int(r[10]) if r[10] is not None else None,
                }
            )
        return {"ok": True, "value": out, "Count": len(out)}


@app.post("/events/process")
def process_events_endpoint(limit: int = 100, dry_run: bool = False, character_key: Optional[str] = None) -> ProcessResult:
    try:
        p, a = autotune_process_events(limit=int(limit), dry_run=bool(dry_run), character_key=character_key)
        return ProcessResult(ok=True, processed_events=p, applied_changes=a, dry_run=bool(dry_run))
    except Exception as e:
        logger.exception("events/process failed: %s", str(e))
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/autotune/policy")
def get_autotune_policy(prefix: str = "") -> Dict[str, Any]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        if prefix:
            cur.execute(
                "SELECT ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, COALESCE(SignalsJson,N'{}'), UpdatedAt "
                "FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey LIKE ? ORDER BY ParameterKey",
                prefix + "%",
            )
        else:
            cur.execute(
                "SELECT ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, COALESCE(SignalsJson,N'{}'), UpdatedAt "
                "FROM dbo.ParameterAutoTunePolicy ORDER BY ParameterKey"
            )

        rows = cur.fetchall()
        out = []
        for r in rows:
            out.append(
                {
                    "parameter_key": r[0],
                    "enabled": bool(r[1]),
                    "min_allowed": int(r[2]) if r[2] is not None else 0,
                    "max_allowed": int(r[3]) if r[3] is not None else 100,
                    "learn_rate": float(r[4]) if r[4] is not None else 0.0,
                    "signals": _parse_json_safe(r[5]) or {},
                    "updated_at": r[6].isoformat() if r[6] else None,
                }
            )
        return {"ok": True, "value": out, "Count": len(out)}


@app.post("/autotune/policy/set")
def set_autotune_policy(payload: PolicySetIn) -> Dict[str, Any]:
    if not payload.parameter_key:
        raise HTTPException(status_code=400, detail="parameter_key required")

    with get_cnx(autocommit=False) as cn:
        cur = cn.cursor()
        enabled, min_a, max_a, lr, sig = _get_policy(cur, payload.parameter_key)

        if payload.enabled is not None:
            enabled = bool(payload.enabled)
        if payload.min_allowed is not None:
            min_a = int(payload.min_allowed)
        if payload.max_allowed is not None:
            max_a = int(payload.max_allowed)
        if payload.learn_rate is not None:
            lr = float(payload.learn_rate)
        if payload.signals is not None:
            sig = payload.signals

        cur.execute(
            "MERGE dbo.ParameterAutoTunePolicy AS tgt "
            "USING (SELECT ? AS ParameterKey) AS src "
            "ON (tgt.ParameterKey=src.ParameterKey) "
            "WHEN MATCHED THEN UPDATE SET Enabled=?, MinAllowed=?, MaxAllowed=?, LearnRate=?, SignalsJson=?, UpdatedAt=sysdatetime() "
            "WHEN NOT MATCHED THEN INSERT(ParameterKey,Enabled,MinAllowed,MaxAllowed,LearnRate,SignalsJson,UpdatedAt) "
            "VALUES(?,?,?,?,?,?,sysdatetime());",
            payload.parameter_key,
            1 if enabled else 0,
            int(min_a),
            int(max_a),
            float(lr),
            json.dumps(sig, ensure_ascii=False),
            payload.parameter_key,
            1 if enabled else 0,
            int(min_a),
            int(max_a),
            float(lr),
            json.dumps(sig, ensure_ascii=False),
        )
        cn.commit()

    return {"ok": True}


# -----------------------------
# Startup
# -----------------------------
@app.on_event("startup")
def _on_startup() -> None:
    if AUTOTUNE_BACKGROUND:
        t = threading.Thread(target=_autotune_loop, name="autotune-loop", daemon=True)
        t.start()
        logger.info(
            "Autotune background worker started (interval=%ss, max_events=%s).",
            AUTOTUNE_INTERVAL_SEC,
            AUTOTUNE_MAX_EVENTS,
        )
    else:
        logger.info("Autotune background worker disabled (AUTOTUNE_BACKGROUND=0).")