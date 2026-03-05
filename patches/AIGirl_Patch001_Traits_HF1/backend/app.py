# -*- coding: utf-8 -*-
"""
AIGirl Backend (local/offline)
Patch 001: character traits + thoughts + autotune policy

This backend intentionally does not call any external cloud APIs.
It only works with local services and MS SQL.
"""
from __future__ import annotations

import json
import os
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

import pyodbc
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, ".env"))

APP_VERSION = "0.2.0-patch001"

app = FastAPI(title="AIGirl Backend", version=APP_VERSION)


def _env(name: str, default: Optional[str] = None) -> Optional[str]:
    v = os.getenv(name)
    if v is None or str(v).strip() == "":
        return default
    return v


def get_cnx(autocommit: bool = False) -> pyodbc.Connection:
    """
    Create a DB connection. Prefer SQL auth (DB_USER/DB_PASSWORD) if provided,
    otherwise fall back to Integrated Security.
    """
    driver = _env("DB_DRIVER", "ODBC Driver 17 for SQL Server")
    server = _env("DB_SERVER")
    database = _env("DB_NAME", "AIGirl")
    user = _env("DB_USER")
    pwd = _env("DB_PASSWORD")

    if not server:
        raise RuntimeError("DB_SERVER is not set in backend/.env")

    if user and pwd:
        cs = (
            f"Driver={{{driver}}};"
            f"Server={server};"
            f"Database={database};"
            f"UID={user};"
            f"PWD={pwd};"
            "TrustServerCertificate=yes;"
        )
    else:
        cs = (
            f"Driver={{{driver}}};"
            f"Server={server};"
            f"Database={database};"
            "Trusted_Connection=yes;"
            "TrustServerCertificate=yes;"
        )

    return pyodbc.connect(cs, autocommit=autocommit)


def fetch_all(sql: str, params: Tuple[Any, ...] = ()) -> List[Dict[str, Any]]:
    with get_cnx(autocommit=True) as cn:
        cur = cn.cursor()
        cur.execute(sql, params)
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]


def fetch_one(sql: str, params: Tuple[Any, ...] = ()) -> Optional[Dict[str, Any]]:
    rows = fetch_all(sql, params)
    return rows[0] if rows else None


def _character_row(character_key: str) -> Dict[str, Any]:
    row = fetch_one(
        """
        SELECT TOP (1) Id, [Key], DisplayName, Surname, [Name], DistinctiveMarksJson, NotesRu
        FROM dbo.Characters
        WHERE [Key] = ?
        """,
        (character_key,),
    )
    if not row:
        raise HTTPException(status_code=404, detail=f"Character not found: {character_key}")
    return row


def _ensure_trait_key(parameter_key: str) -> None:
    if not (
        parameter_key.startswith("trait.")
        or parameter_key.startswith("state.")
        or parameter_key.startswith("voice.")
    ):
        raise HTTPException(
            status_code=400,
            detail="Only trait./state./voice. keys are allowed in this endpoint.",
        )


def _get_param_def(parameter_key: str) -> Dict[str, Any]:
    row = fetch_one(
        """
        SELECT TOP(1)
          [Key], NameRu, GroupRu,
          MinValue, MaxValue, DefaultValue, HintRu,
          ISNULL(ValueType, N'slider_int') AS ValueType,
          UnitRu, StepValue
        FROM dbo.ParameterDefinitions
        WHERE [Key] = ?
        """,
        (parameter_key,),
    )
    if not row:
        raise HTTPException(status_code=404, detail=f"Unknown parameter: {parameter_key}")
    return row


def _choose_thought(
    character_key: str, parameter_key: str, value_int: int, delta_int: Optional[int]
) -> str:
    """
    Pick a thought template based on value 0..100 and append trend line based on last delta.
    Priority: character-specific template > default (CharacterKey NULL).
    """
    # Character-specific first
    row = fetch_one(
        """
        SELECT TOP(1) TextRu, TrendUpTextRu, TrendDownTextRu
        FROM dbo.ParameterThoughtTemplates
        WHERE ParameterKey = ?
          AND CharacterKey = ?
          AND ? BETWEEN BinMin AND BinMax
        """,
        (parameter_key, character_key, value_int),
    )
    if not row:
        row = fetch_one(
            """
            SELECT TOP(1) TextRu, TrendUpTextRu, TrendDownTextRu
            FROM dbo.ParameterThoughtTemplates
            WHERE ParameterKey = ?
              AND CharacterKey IS NULL
              AND ? BETWEEN BinMin AND BinMax
            """,
            (parameter_key, value_int),
        )

    if row:
        text = row.get("TextRu") or ""
        up = row.get("TrendUpTextRu") or ""
        down = row.get("TrendDownTextRu") or ""
    else:
        # Fallback (should rarely happen if patch seeded templates)
        text = "Я воспринимаю это спокойно и стараюсь держать баланс."
        up = "Я замечаю, что это качество во мне усиливается."
        down = "Похоже, я стала более сдержанной в этой стороне."

    if delta_int is None or delta_int == 0:
        return text
    if delta_int > 0 and up:
        return f"{text} {up}"
    if delta_int < 0 and down:
        return f"{text} {down}"
    return text


@app.get("/health")
def health() -> Dict[str, Any]:
    return {"ok": True, "version": APP_VERSION, "ts": datetime.utcnow().isoformat() + "Z"}


@app.get("/characters")
def characters() -> List[Dict[str, Any]]:
    rows = fetch_all(
        """
        SELECT [Key], DisplayName, Surname, [Name], DistinctiveMarksJson, NotesRu
        FROM dbo.Characters
        ORDER BY Id
        """
    )
    # normalize json columns
    for r in rows:
        dj = r.get("DistinctiveMarksJson")
        if isinstance(dj, str) and dj.strip():
            try:
                r["DistinctiveMarks"] = json.loads(dj)
            except Exception:
                r["DistinctiveMarks"] = None
        else:
            r["DistinctiveMarks"] = None
    return rows


@app.get("/parameters")
def parameters(
    prefix: Optional[str] = Query(default=None, description="Optional key prefix filter, e.g. trait. or state."),
) -> List[Dict[str, Any]]:
    if prefix:
        rows = fetch_all(
            """
            SELECT
              [Key], NameRu, GroupRu,
              MinValue, MaxValue, DefaultValue, HintRu,
              ISNULL(ValueType, N'slider_int') AS ValueType,
              UnitRu, StepValue
            FROM dbo.ParameterDefinitions
            WHERE [Key] LIKE ?
            ORDER BY GroupRu, NameRu
            """,
            (prefix + "%",),
        )
    else:
        rows = fetch_all(
            """
            SELECT
              [Key], NameRu, GroupRu,
              MinValue, MaxValue, DefaultValue, HintRu,
              ISNULL(ValueType, N'slider_int') AS ValueType,
              UnitRu, StepValue
            FROM dbo.ParameterDefinitions
            ORDER BY GroupRu, NameRu
            """
        )
    return rows


@app.get("/characters/{character_key}/traits")
def character_traits(
    character_key: str,
    include_state: bool = True,
    include_voice: bool = True,
) -> Dict[str, Any]:
    c = _character_row(character_key)
    char_id = int(c["Id"])

    where = ["p.[Key] LIKE N'trait.%'"]
    if include_state:
        where.append("p.[Key] LIKE N'state.%'")
    if include_voice:
        where.append("p.[Key] LIKE N'voice.%'")
    where_sql = " OR ".join(where)

    defs = fetch_all(
        f"""
        SELECT
          p.[Key] AS ParameterKey,
          p.NameRu, p.GroupRu,
          p.MinValue, p.MaxValue, p.DefaultValue, p.HintRu,
          ISNULL(p.ValueType, N'slider_int') AS ValueType,
          p.UnitRu, p.StepValue,
          COALESCE(v.ValueInt, p.DefaultValue) AS ValueInt
        FROM dbo.ParameterDefinitions p
        LEFT JOIN dbo.CharacterParameterValues v
          ON v.ParameterKey = p.[Key]
         AND v.CharacterId = ?
        WHERE ({where_sql})
        ORDER BY p.GroupRu, p.NameRu
        """,
        (char_id,),
    )

    # Fetch last delta per parameter in one query
    deltas = fetch_all(
        """
        WITH h AS (
          SELECT CharacterId, ParameterKey, DeltaInt,
                 ROW_NUMBER() OVER(PARTITION BY CharacterId, ParameterKey ORDER BY CreatedAt DESC, Id DESC) AS rn
          FROM dbo.CharacterParameterHistory
          WHERE CharacterId = ?
        )
        SELECT ParameterKey, DeltaInt
        FROM h
        WHERE rn = 1
        """,
        (char_id,),
    )
    delta_map = {d["ParameterKey"]: d.get("DeltaInt") for d in deltas}

    items = []
    for d in defs:
        v = int(d.get("ValueInt") or d.get("DefaultValue") or 0)
        delta = delta_map.get(d["ParameterKey"])
        thought = _choose_thought(character_key, d["ParameterKey"], v, delta if delta is not None else 0)
        items.append(
            {
                "key": d["ParameterKey"],
                "nameRu": d["NameRu"],
                "groupRu": d["GroupRu"],
                "min": int(d["MinValue"]),
                "max": int(d["MaxValue"]),
                "default": int(d["DefaultValue"]),
                "hintRu": d.get("HintRu") or "",
                "valueType": d.get("ValueType") or "slider_int",
                "unitRu": d.get("UnitRu"),
                "step": int(d.get("StepValue") or 1),
                "valueInt": v,
                "trendDelta": int(delta or 0),
                "thoughtRu": thought,
            }
        )

    return {"character": {"key": c["Key"], "displayName": c["DisplayName"]}, "items": items}


class TraitSetRequest(BaseModel):
    parameter_key: str = Field(..., description="Key of parameter, must start with trait./state./voice.")
    value_int: int = Field(..., description="New integer value, must be within [min,max] from ParameterDefinitions.")
    reason_ru: Optional[str] = Field(default=None, description="Optional reason for audit/history.")
    source: str = Field(default="admin", description="Source marker: admin/autotune/system.")


@app.post("/characters/{character_key}/traits/set")
def set_character_trait(character_key: str, req: TraitSetRequest) -> Dict[str, Any]:
    _ensure_trait_key(req.parameter_key)

    c = _character_row(character_key)
    char_id = int(c["Id"])

    p = _get_param_def(req.parameter_key)
    minv = int(p["MinValue"])
    maxv = int(p["MaxValue"])
    if req.value_int < minv or req.value_int > maxv:
        raise HTTPException(status_code=400, detail=f"value_int must be in [{minv},{maxv}] for {req.parameter_key}")

    with get_cnx(autocommit=False) as cn:
        cur = cn.cursor()

        # old value (fallback to default)
        cur.execute(
            "SELECT ValueInt FROM dbo.CharacterParameterValues WHERE CharacterId=? AND ParameterKey=?",
            (char_id, req.parameter_key),
        )
        row = cur.fetchone()
        old_val = row[0] if row and row[0] is not None else int(p["DefaultValue"])

        # upsert
        if row:
            cur.execute(
                """
                UPDATE dbo.CharacterParameterValues
                SET ValueInt=?, UpdatedAt=sysdatetime()
                WHERE CharacterId=? AND ParameterKey=?
                """,
                (req.value_int, char_id, req.parameter_key),
            )
        else:
            cur.execute(
                """
                INSERT INTO dbo.CharacterParameterValues(CharacterId, ParameterKey, ValueInt)
                VALUES(?, ?, ?)
                """,
                (char_id, req.parameter_key, req.value_int),
            )

        delta = int(req.value_int) - int(old_val)
        cur.execute(
            """
            INSERT INTO dbo.CharacterParameterHistory(CharacterId, ParameterKey, OldValueInt, NewValueInt, DeltaInt, ReasonRu, Source)
            VALUES(?, ?, ?, ?, ?, ?, ?)
            """,
            (
                char_id,
                req.parameter_key,
                int(old_val),
                int(req.value_int),
                int(delta),
                req.reason_ru,
                req.source,
            ),
        )

        cn.commit()

    # return updated view item
    thought = _choose_thought(character_key, req.parameter_key, int(req.value_int), delta)
    return {
        "characterKey": character_key,
        "parameterKey": req.parameter_key,
        "oldValueInt": int(old_val),
        "newValueInt": int(req.value_int),
        "deltaInt": int(delta),
        "thoughtRu": thought,
    }


@app.get("/characters/{character_key}/traits/history")
def trait_history(
    character_key: str,
    parameter_key: str = Query(...),
    limit: int = Query(default=50, ge=1, le=500),
) -> Dict[str, Any]:
    _ensure_trait_key(parameter_key)

    c = _character_row(character_key)
    char_id = int(c["Id"])

    rows = fetch_all(
        """
        SELECT TOP (?)
          Id, ParameterKey, OldValueInt, NewValueInt, DeltaInt, ReasonRu, Source, CreatedAt
        FROM dbo.CharacterParameterHistory
        WHERE CharacterId=? AND ParameterKey=?
        ORDER BY CreatedAt DESC, Id DESC
        """,
        (limit, char_id, parameter_key),
    )
    return {"characterKey": character_key, "parameterKey": parameter_key, "items": rows}


@app.get("/thought_templates/{parameter_key}")
def get_thought_templates(
    parameter_key: str,
    character_key: Optional[str] = Query(default=None),
) -> Dict[str, Any]:
    # parameter_key may be for any parameter, but usually trait/state/voice
    rows = fetch_all(
        """
        SELECT ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu, UpdatedAt
        FROM dbo.ParameterThoughtTemplates
        WHERE ParameterKey = ?
          AND (? IS NULL OR CharacterKey = ? OR CharacterKey IS NULL)
        ORDER BY
          CASE WHEN CharacterKey IS NULL THEN 0 ELSE 1 END,
          CharacterKey, BinMin
        """,
        (parameter_key, character_key, character_key),
    )
    return {"parameterKey": parameter_key, "items": rows}


class ThoughtTemplateUpsert(BaseModel):
    character_key: Optional[str] = Field(default=None, description="NULL for default templates used by all characters.")
    bin_min: int = Field(..., ge=0, le=100)
    bin_max: int = Field(..., ge=0, le=100)
    text_ru: str = Field(..., min_length=1, max_length=1024)
    trend_up_text_ru: Optional[str] = Field(default=None, max_length=512)
    trend_down_text_ru: Optional[str] = Field(default=None, max_length=512)


@app.post("/thought_templates/{parameter_key}/upsert")
def upsert_thought_template(parameter_key: str, req: ThoughtTemplateUpsert) -> Dict[str, Any]:
    if req.bin_min > req.bin_max:
        raise HTTPException(status_code=400, detail="bin_min must be <= bin_max")

    with get_cnx(autocommit=False) as cn:
        cur = cn.cursor()
        # upsert by PK
        cur.execute(
            """
            IF EXISTS (
              SELECT 1 FROM dbo.ParameterThoughtTemplates
              WHERE ParameterKey = ?
                AND ((CharacterKey IS NULL AND ? IS NULL) OR (CharacterKey = ?))
                AND BinMin = ? AND BinMax = ?
            )
            BEGIN
              UPDATE dbo.ParameterThoughtTemplates
              SET TextRu = ?,
                  TrendUpTextRu = ?,
                  TrendDownTextRu = ?,
                  UpdatedAt = sysdatetime()
              WHERE ParameterKey = ?
                AND ((CharacterKey IS NULL AND ? IS NULL) OR (CharacterKey = ?))
                AND BinMin = ? AND BinMax = ?;
            END
            ELSE
            BEGIN
              INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
              VALUES(?, ?, ?, ?, ?, ?, ?);
            END
            """,
            (
                parameter_key,
                req.character_key,
                req.character_key,
                int(req.bin_min),
                int(req.bin_max),
                req.text_ru,
                req.trend_up_text_ru,
                req.trend_down_text_ru,
                parameter_key,
                req.character_key,
                req.character_key,
                int(req.bin_min),
                int(req.bin_max),
                parameter_key,
                req.character_key,
                int(req.bin_min),
                int(req.bin_max),
                req.text_ru,
                req.trend_up_text_ru,
                req.trend_down_text_ru,
            ),
        )
        cn.commit()

    return {"ok": True, "parameterKey": parameter_key, "characterKey": req.character_key, "binMin": req.bin_min, "binMax": req.bin_max}
