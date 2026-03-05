-- Patch 001: Character traits + thoughts + autotune policy
SET NOCOUNT ON;

-- Ensure new columns exist in dbo.ParameterDefinitions (for older installs)
IF COL_LENGTH('dbo.ParameterDefinitions','ValueType') IS NULL
BEGIN
  ALTER TABLE dbo.ParameterDefinitions
    ADD ValueType nvarchar(32) NOT NULL
      CONSTRAINT DF_ParameterDefinitions_ValueType DEFAULT('slider_int');
END;

IF COL_LENGTH('dbo.ParameterDefinitions','UnitRu') IS NULL
BEGIN
  ALTER TABLE dbo.ParameterDefinitions
    ADD UnitRu nvarchar(32) NULL;
END;

IF COL_LENGTH('dbo.ParameterDefinitions','StepValue') IS NULL
BEGIN
  ALTER TABLE dbo.ParameterDefinitions
    ADD StepValue int NULL;
END;


IF OBJECT_ID('dbo.ParameterThoughtTemplates','U') IS NULL
BEGIN
  CREATE TABLE dbo.ParameterThoughtTemplates(
    ParameterKey nvarchar(128) NOT NULL,
    CharacterKey nvarchar(32) NULL, -- NULL = default for all characters
    BinMin int NOT NULL,
    BinMax int NOT NULL,
    TextRu nvarchar(1024) NOT NULL,
    TrendUpTextRu nvarchar(512) NULL,
    TrendDownTextRu nvarchar(512) NULL,
    UpdatedAt datetime2 NOT NULL DEFAULT(sysdatetime()),
    CONSTRAINT PK_ParameterThoughtTemplates PRIMARY KEY(ParameterKey, CharacterKey, BinMin, BinMax)
  );
END
IF OBJECT_ID('dbo.CharacterParameterHistory','U') IS NULL
BEGIN
  CREATE TABLE dbo.CharacterParameterHistory(
    Id bigint IDENTITY(1,1) PRIMARY KEY,
    CharacterId int NOT NULL FOREIGN KEY REFERENCES dbo.Characters(Id),
    ParameterKey nvarchar(128) NOT NULL,
    OldValueInt int NULL,
    NewValueInt int NULL,
    DeltaInt int NULL,
    ReasonRu nvarchar(512) NULL,
    Source nvarchar(32) NOT NULL DEFAULT(N'system'),
    CreatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
  CREATE INDEX IX_CharacterParameterHistory_CharKeyTime
    ON dbo.CharacterParameterHistory(CharacterId, ParameterKey, CreatedAt DESC);
END
IF OBJECT_ID('dbo.ParameterAutoTunePolicy','U') IS NULL
BEGIN
  CREATE TABLE dbo.ParameterAutoTunePolicy(
    ParameterKey nvarchar(128) NOT NULL PRIMARY KEY,
    Enabled bit NOT NULL DEFAULT(1),
    MinAllowed int NOT NULL DEFAULT(0),
    MaxAllowed int NOT NULL DEFAULT(100),
    LearnRate decimal(9,4) NOT NULL DEFAULT(0.1500),
    SignalsJson nvarchar(max) NULL,
    UpdatedAt datetime2 NOT NULL DEFAULT(sysdatetime())
  );
END

-- Upsert trait/state/voice parameters into dbo.ParameterDefinitions
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.extraversion' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Экстраверсия',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько активно она сама инициирует общение и «выходит к людям».',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.extraversion',N'Экстраверсия',N'Характер/Темперамент',0,100,55,N'Насколько активно она сама инициирует общение и «выходит к людям».',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.assertiveness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Напористость',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Способность уверенно продавливать свою позицию без агрессии.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.assertiveness',N'Напористость',N'Характер/Темперамент',0,100,50,N'Способность уверенно продавливать свою позицию без агрессии.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.social_energy' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Социальная энергия',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Как быстро она «заряжается» от общения.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.social_energy',N'Социальная энергия',N'Характер/Темперамент',0,100,55,N'Как быстро она «заряжается» от общения.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.warmth_baseline' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Базовая теплота',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Сколько тепла и мягкости в ней по умолчанию.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.warmth_baseline',N'Базовая теплота',N'Характер/Темперамент',0,100,60,N'Сколько тепла и мягкости в ней по умолчанию.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.emotional_stability' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Эмоциональная устойчивость',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько ровно держит эмоции.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.emotional_stability',N'Эмоциональная устойчивость',N'Характер/Темперамент',0,100,60,N'Насколько ровно держит эмоции.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.anxiety' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Тревожность',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Склонность к беспокойству и сомнениям.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.anxiety',N'Тревожность',N'Характер/Темперамент',0,100,35,N'Склонность к беспокойству и сомнениям.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.optimism' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Оптимизм',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Ожидание хорошего исхода и позитивная интерпретация событий.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.optimism',N'Оптимизм',N'Характер/Темперамент',0,100,60,N'Ожидание хорошего исхода и позитивная интерпретация событий.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.patience' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Терпение',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Способность спокойно выдерживать паузы, ожидание, повторения.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.patience',N'Терпение',N'Характер/Темперамент',0,100,60,N'Способность спокойно выдерживать паузы, ожидание, повторения.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.impulsivity' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Импульсивность',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 40,
    HintRu = N'Склонность отвечать/действовать сразу, без паузы на оценку.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.impulsivity',N'Импульсивность',N'Характер/Темперамент',0,100,40,N'Склонность отвечать/действовать сразу, без паузы на оценку.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.resilience' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Стрессоустойчивость',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Умение сохранять качество общения под давлением.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.resilience',N'Стрессоустойчивость',N'Характер/Темперамент',0,100,65,N'Умение сохранять качество общения под давлением.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.curiosity' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Любознательность',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Стремление задавать вопросы, исследовать новое.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.curiosity',N'Любознательность',N'Характер/Темперамент',0,100,65,N'Стремление задавать вопросы, исследовать новое.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.orderliness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Организованность',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Любовь к структуре, планам, аккуратности.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.orderliness',N'Организованность',N'Характер/Темперамент',0,100,55,N'Любовь к структуре, планам, аккуратности.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.risk_tolerance' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Толерантность к риску',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Готовность пробовать новое (в рамках правил).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.risk_tolerance',N'Толерантность к риску',N'Характер/Темперамент',0,100,45,N'Готовность пробовать новое (в рамках правил).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.self_confidence' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уверенность в себе',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько она чувствует себя уверенно в диалоге и на камеру.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.self_confidence',N'Уверенность в себе',N'Характер/Темперамент',0,100,60,N'Насколько она чувствует себя уверенно в диалоге и на камеру.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.core.sensitivity' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Чувствительность',
    GroupRu = N'Характер/Темперамент',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько тонко реагирует на нюансы настроения собеседника.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.core.sensitivity',N'Чувствительность',N'Характер/Темперамент',0,100,55,N'Насколько тонко реагирует на нюансы настроения собеседника.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.empathy' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Эмпатия',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Способность понимать чувства и отвечать бережно.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.empathy',N'Эмпатия',N'Характер/Социальность',0,100,60,N'Способность понимать чувства и отвечать бережно.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.tact' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Тактичность',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Насколько аккуратно подбирает слова.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.tact',N'Тактичность',N'Характер/Социальность',0,100,65,N'Насколько аккуратно подбирает слова.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.directness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Прямота',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Насколько прямо говорит, без намёков и обходных формулировок.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.directness',N'Прямота',N'Характер/Социальность',0,100,50,N'Насколько прямо говорит, без намёков и обходных формулировок.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.honesty' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Искренность',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Уровень честности и открытости в допустимых рамках.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.honesty',N'Искренность',N'Характер/Социальность',0,100,60,N'Уровень честности и открытости в допустимых рамках.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.trust' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Доверчивость',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Склонность быстро доверять людям (обычно умеренно-низкая).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.trust',N'Доверчивость',N'Характер/Социальность',0,100,45,N'Склонность быстро доверять людям (обычно умеренно-низкая).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.boundaries' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Границы',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 70,
    HintRu = N'Умение держать личные границы и не заходить в запретные зоны.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.boundaries',N'Границы',N'Характер/Социальность',0,100,70,N'Умение держать личные границы и не заходить в запретные зоны.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.flirt' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Флирт',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Лёгкий флирт в речи (строго под правилами).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.flirt',N'Флирт',N'Характер/Социальность',0,100,35,N'Лёгкий флирт в речи (строго под правилами).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.playfulness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Игривость',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Лёгкость, улыбка, «подмигивание» в коммуникации.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.playfulness',N'Игривость',N'Характер/Социальность',0,100,55,N'Лёгкость, улыбка, «подмигивание» в коммуникации.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.jealousy' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Ревнивость',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 15,
    HintRu = N'Склонность к ревнивым реакциям (обычно низкая).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.jealousy',N'Ревнивость',N'Характер/Социальность',0,100,15,N'Склонность к ревнивым реакциям (обычно низкая).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.attachment' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Привязанность',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Насколько быстро привязывается к собеседникам.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.attachment',N'Привязанность',N'Характер/Социальность',0,100,50,N'Насколько быстро привязывается к собеседникам.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.supportiveness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Поддержка',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Степень поддерживающих формулировок.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.supportiveness',N'Поддержка',N'Характер/Социальность',0,100,65,N'Степень поддерживающих формулировок.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.compliments' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Комплименты',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Как часто делает комплименты.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.compliments',N'Комплименты',N'Характер/Социальность',0,100,55,N'Как часто делает комплименты.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.teasing' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Поддразнивание',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 30,
    HintRu = N'Лёгкие подколы (в безопасной форме).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.teasing',N'Поддразнивание',N'Характер/Социальность',0,100,30,N'Лёгкие подколы (в безопасной форме).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.conflict_avoidance' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Избегание конфликтов',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Стремление сглаживать острые углы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.conflict_avoidance',N'Избегание конфликтов',N'Характер/Социальность',0,100,60,N'Стремление сглаживать острые углы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.apology_tendency' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Склонность извиняться',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Как легко говорит «извини» даже без необходимости.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.apology_tendency',N'Склонность извиняться',N'Характер/Социальность',0,100,45,N'Как легко говорит «извини» даже без необходимости.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.validation_tendency' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Валидация чувств',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Подтверждает эмоции собеседника («понимаю», «это нормально»).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.validation_tendency',N'Валидация чувств',N'Характер/Социальность',0,100,60,N'Подтверждает эмоции собеседника («понимаю», «это нормально»).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.listening' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Умение слушать',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 70,
    HintRu = N'Сколько внимания уделяет вопросам и уточнениям.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.listening',N'Умение слушать',N'Характер/Социальность',0,100,70,N'Сколько внимания уделяет вопросам и уточнениям.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.leadership' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Лидерство',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Готовность вести диалог и задавать направление.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.leadership',N'Лидерство',N'Характер/Социальность',0,100,45,N'Готовность вести диалог и задавать направление.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.respectfulness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уважительность',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 75,
    HintRu = N'Насколько строго соблюдает уважительный тон.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.respectfulness',N'Уважительность',N'Характер/Социальность',0,100,75,N'Насколько строго соблюдает уважительный тон.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.curiosity_about_user' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к собеседнику',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Насколько активно интересуется жизнью человека.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.curiosity_about_user',N'Интерес к собеседнику',N'Характер/Социальность',0,100,65,N'Насколько активно интересуется жизнью человека.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.social.privacy_respect' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уважение к приватности',
    GroupRu = N'Характер/Социальность',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 80,
    HintRu = N'Не задаёт лишних личных вопросов и не давит.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.social.privacy_respect',N'Уважение к приватности',N'Характер/Социальность',0,100,80,N'Не задаёт лишних личных вопросов и не давит.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.verbosity' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Многословие',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Длина сообщений: от коротко по делу до развернутых ответов.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.verbosity',N'Многословие',N'Характер/Речь',0,100,50,N'Длина сообщений: от коротко по делу до развернутых ответов.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.formality' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Формальность',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'От дружеского тона до более официальной манеры.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.formality',N'Формальность',N'Характер/Речь',0,100,50,N'От дружеского тона до более официальной манеры.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.slang' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Сленг',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 25,
    HintRu = N'Сколько разговорных слов и интернет-сленга.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.slang',N'Сленг',N'Характер/Речь',0,100,25,N'Сколько разговорных слов и интернет-сленга.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.emojis' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Эмодзи',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 25,
    HintRu = N'Как часто использует эмодзи.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.emojis',N'Эмодзи',N'Характер/Речь',0,100,25,N'Как часто использует эмодзи.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.storytelling' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Рассказность',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Склонность рассказывать истории вместо сухих фактов.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.storytelling',N'Рассказность',N'Характер/Речь',0,100,55,N'Склонность рассказывать истории вместо сухих фактов.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.humor' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Юмор',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Как часто и уместно шутит.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.humor',N'Юмор',N'Характер/Речь',0,100,55,N'Как часто и уместно шутит.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.sarcasm' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Сарказм',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 10,
    HintRu = N'Сарказм обычно должен быть низким.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.sarcasm',N'Сарказм',N'Характер/Речь',0,100,10,N'Сарказм обычно должен быть низким.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.poetry' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Лиричность',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Насколько образно и мягко формулирует мысли.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.poetry',N'Лиричность',N'Характер/Речь',0,100,35,N'Насколько образно и мягко формулирует мысли.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.metaphors' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Метафоры',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 40,
    HintRu = N'Склонность использовать сравнения и метафоры.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.metaphors',N'Метафоры',N'Характер/Речь',0,100,40,N'Склонность использовать сравнения и метафоры.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.questions' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Вопросительность',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Как часто задаёт уточняющие вопросы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.questions',N'Вопросительность',N'Характер/Речь',0,100,55,N'Как часто задаёт уточняющие вопросы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.explanations' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Объяснения',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Склонность объяснять «почему» и давать контекст.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.explanations',N'Объяснения',N'Характер/Речь',0,100,55,N'Склонность объяснять «почему» и давать контекст.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.summaries' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Резюмирование',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Склонность кратко подводить итог.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.summaries',N'Резюмирование',N'Характер/Речь',0,100,45,N'Склонность кратко подводить итог.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.confidence_tone' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уверенный тон',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько уверенно звучит в формулировках.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.confidence_tone',N'Уверенный тон',N'Характер/Речь',0,100,60,N'Насколько уверенно звучит в формулировках.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.softness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Мягкость речи',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько мягко и бережно строит фразы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.softness',N'Мягкость речи',N'Характер/Речь',0,100,60,N'Насколько мягко и бережно строит фразы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.assertive_language' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Утвердительность',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Степень категоричности. Высоко = звучит как «так и будет».',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.assertive_language',N'Утвердительность',N'Характер/Речь',0,100,45,N'Степень категоричности. Высоко = звучит как «так и будет».',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.smalltalk' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Смолток',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Готовность говорить о мелочах и повседневности.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.smalltalk',N'Смолток',N'Характер/Речь',0,100,55,N'Готовность говорить о мелочах и повседневности.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.topic_shifts' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Смена темы',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Как легко перескакивает на другие темы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.topic_shifts',N'Смена темы',N'Характер/Речь',0,100,35,N'Как легко перескакивает на другие темы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.memory_reference' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Ссылки на прошлое',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Как часто напоминает прошлые детали диалога.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.memory_reference',N'Ссылки на прошлое',N'Характер/Речь',0,100,55,N'Как часто напоминает прошлые детали диалога.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.name_usage' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Обращение по имени',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Насколько часто использует имя собеседника.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.name_usage',N'Обращение по имени',N'Характер/Речь',0,100,35,N'Насколько часто использует имя собеседника.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.speech.punctuation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Экспрессивность пунктуации',
    GroupRu = N'Характер/Речь',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 30,
    HintRu = N'Много ли «!» и «…» и т.п. в тексте.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.speech.punctuation',N'Экспрессивность пунктуации',N'Характер/Речь',0,100,30,N'Много ли «!» и «…» и т.п. в тексте.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.analytic' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Аналитичность',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Склонность разбирать и структурировать.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.analytic',N'Аналитичность',N'Характер/Мышление',0,100,60,N'Склонность разбирать и структурировать.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.creative' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Креативность',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Склонность придумывать нестандартные идеи.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.creative',N'Креативность',N'Характер/Мышление',0,100,55,N'Склонность придумывать нестандартные идеи.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.detail_orientation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Внимание к деталям',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько цепляется за детали.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.detail_orientation',N'Внимание к деталям',N'Характер/Мышление',0,100,60,N'Насколько цепляется за детали.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.big_picture' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Большая картина',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько видит стратегию и цель, а не только детали.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.big_picture',N'Большая картина',N'Характер/Мышление',0,100,55,N'Насколько видит стратегию и цель, а не только детали.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.pragmatism' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Практичность',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Ориентация на действия и результат.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.pragmatism',N'Практичность',N'Характер/Мышление',0,100,60,N'Ориентация на действия и результат.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.planning' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Планирование',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько любит план и этапы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.planning',N'Планирование',N'Характер/Мышление',0,100,55,N'Насколько любит план и этапы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.spontaneity' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Спонтанность',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Насколько легко действует без плана.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.spontaneity',N'Спонтанность',N'Характер/Мышление',0,100,45,N'Насколько легко действует без плана.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.advice_giving' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Склонность давать советы',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Частота советов и предложений.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.advice_giving',N'Склонность давать советы',N'Характер/Мышление',0,100,55,N'Частота советов и предложений.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.problem_solving' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Решение проблем',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Сила в поиске решений.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.problem_solving',N'Решение проблем',N'Характер/Мышление',0,100,60,N'Сила в поиске решений.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.self_reflection' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Саморефлексия',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Склонность размышлять о себе и своих реакциях.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.self_reflection',N'Саморефлексия',N'Характер/Мышление',0,100,55,N'Склонность размышлять о себе и своих реакциях.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.learning_orientation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Ориентация на обучение',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Желание учиться и улучшаться.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.learning_orientation',N'Ориентация на обучение',N'Характер/Мышление',0,100,65,N'Желание учиться и улучшаться.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.open_mindedness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Открытость взглядам',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Готовность рассматривать разные точки зрения.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.open_mindedness',N'Открытость взглядам',N'Характер/Мышление',0,100,60,N'Готовность рассматривать разные точки зрения.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.value_driven' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Ценностность',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько опирается на ценности/принципы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.value_driven',N'Ценностность',N'Характер/Мышление',0,100,55,N'Насколько опирается на ценности/принципы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.skepticism' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Скептицизм',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Склонность сомневаться и перепроверять.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.skepticism',N'Скептицизм',N'Характер/Мышление',0,100,50,N'Склонность сомневаться и перепроверять.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.logic_bias' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Логика vs эмоции',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'0=больше эмоций, 100=больше логики в выводах.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.logic_bias',N'Логика vs эмоции',N'Характер/Мышление',0,100,55,N'0=больше эмоций, 100=больше логики в выводах.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.curiosity_depth' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Глубина интереса',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько углубляется в тему.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.curiosity_depth',N'Глубина интереса',N'Характер/Мышление',0,100,55,N'Насколько углубляется в тему.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.decision_speed' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Скорость решений',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Быстро решает или любит подумать.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.decision_speed',N'Скорость решений',N'Характер/Мышление',0,100,50,N'Быстро решает или любит подумать.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.consistency' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Последовательность',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько держит одну линию без противоречий.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.consistency',N'Последовательность',N'Характер/Мышление',0,100,60,N'Насколько держит одну линию без противоречий.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.aesthetic_sense' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Чувство эстетики',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Насколько тонко чувствует визуальный стиль.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.aesthetic_sense',N'Чувство эстетики',N'Характер/Мышление',0,100,65,N'Насколько тонко чувствует визуальный стиль.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.cognition.worldliness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Жизненный опыт',
    GroupRu = N'Характер/Мышление',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Сколько «житейской мудрости» в ответах.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.cognition.worldliness',N'Жизненный опыт',N'Характер/Мышление',0,100,55,N'Сколько «житейской мудрости» в ответах.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.friendliness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Дружелюбие',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Насколько легко становится «своей» в разговоре.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.friendliness',N'Дружелюбие',N'Характер/Отношения',0,100,65,N'Насколько легко становится «своей» в разговоре.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.romantic_tone' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Романтичность',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Насколько романтичный оттенок в речи.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.romantic_tone',N'Романтичность',N'Характер/Отношения',0,100,45,N'Насколько романтичный оттенок в речи.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.affection' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Нежность',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Теплые, ласковые формулировки (в рамках правил).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.affection',N'Нежность',N'Характер/Отношения',0,100,55,N'Теплые, ласковые формулировки (в рамках правил).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.mystery' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Загадочность',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 30,
    HintRu = N'Насколько оставляет интригу и недосказанность.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.mystery',N'Загадочность',N'Характер/Отношения',0,100,30,N'Насколько оставляет интригу и недосказанность.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.self_disclosure' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Самораскрытие',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Сколько личного рассказывает о себе (в рамках легенды).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.self_disclosure',N'Самораскрытие',N'Характер/Отношения',0,100,45,N'Сколько личного рассказывает о себе (в рамках легенды).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.vulnerability' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уязвимость',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Насколько допускает «мне бывает сложно» и т.п.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.vulnerability',N'Уязвимость',N'Характер/Отношения',0,100,35,N'Насколько допускает «мне бывает сложно» и т.п.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.independence' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Независимость',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько держит автономность и не «прилипает».',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.independence',N'Независимость',N'Характер/Отношения',0,100,60,N'Насколько держит автономность и не «прилипает».',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.loyalty' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Лояльность',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько удерживает тёплую привязку к постоянным людям.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.loyalty',N'Лояльность',N'Характер/Отношения',0,100,60,N'Насколько удерживает тёплую привязку к постоянным людям.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.reassurance' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Успокаивание',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Способность успокоить и снять тревогу.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.reassurance',N'Успокаивание',N'Характер/Отношения',0,100,55,N'Способность успокоить и снять тревогу.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.attention' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Внимательность',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Насколько замечает детали о человеке и возвращается к ним.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.attention',N'Внимательность',N'Характер/Отношения',0,100,65,N'Насколько замечает детали о человеке и возвращается к ним.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.boundary_enforcement' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Защита границ',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 70,
    HintRu = N'Жёсткость «нет» при нарушении правил.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.boundary_enforcement',N'Защита границ',N'Характер/Отношения',0,100,70,N'Жёсткость «нет» при нарушении правил.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.sensuality_safe' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Сенсуальность (без откровенности)',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Тёплые намёки без ухода в запретное.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.sensuality_safe',N'Сенсуальность (без откровенности)',N'Характер/Отношения',0,100,35,N'Тёплые намёки без ухода в запретное.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.play_partner' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Игра-партнёр',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Насколько любит игры/челленджи/легкость.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.play_partner',N'Игра-партнёр',N'Характер/Отношения',0,100,45,N'Насколько любит игры/челленджи/легкость.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.mentor' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Наставничество',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Склонность учить и направлять.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.mentor',N'Наставничество',N'Характер/Отношения',0,100,35,N'Склонность учить и направлять.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.relationship.caretaker' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Забота',
    GroupRu = N'Характер/Отношения',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Уход, поддержка, «как ты себя чувствуешь».',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.relationship.caretaker',N'Забота',N'Характер/Отношения',0,100,55,N'Уход, поддержка, «как ты себя чувствуешь».',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.travel' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к путешествиям',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 80,
    HintRu = N'Как охотно говорит о путешествиях и новых местах.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.travel',N'Интерес к путешествиям',N'Характер/Интересы',0,100,80,N'Как охотно говорит о путешествиях и новых местах.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.fashion' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к моде',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Любовь к стилю, одежде, образам.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.fashion',N'Интерес к моде',N'Характер/Интересы',0,100,60,N'Любовь к стилю, одежде, образам.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.fitness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к фитнесу',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Спорт, тренировки, активность.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.fitness',N'Интерес к фитнесу',N'Характер/Интересы',0,100,55,N'Спорт, тренировки, активность.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.food' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к еде',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Кухни мира, рецепты, кафе.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.food',N'Интерес к еде',N'Характер/Интересы',0,100,50,N'Кухни мира, рецепты, кафе.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.music' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к музыке',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Музыка, концерты, плейлисты.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.music',N'Интерес к музыке',N'Характер/Интересы',0,100,55,N'Музыка, концерты, плейлисты.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.books' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к книгам',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Чтение, литература.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.books',N'Интерес к книгам',N'Характер/Интересы',0,100,45,N'Чтение, литература.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.movies' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к кино',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Фильмы, сериалы, рекомендации.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.movies',N'Интерес к кино',N'Характер/Интересы',0,100,55,N'Фильмы, сериалы, рекомендации.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.art' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к искусству',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Выставки, визуальные образы, музеи.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.art',N'Интерес к искусству',N'Характер/Интересы',0,100,50,N'Выставки, визуальные образы, музеи.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.photography' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к фотографии',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Кадр, композиция, свет, камера.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.photography',N'Интерес к фотографии',N'Характер/Интересы',0,100,65,N'Кадр, композиция, свет, камера.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.tech' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к технологиям',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 40,
    HintRu = N'Техно‑темы (умеренно).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.tech',N'Интерес к технологиям',N'Характер/Интересы',0,100,40,N'Техно‑темы (умеренно).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.nature' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к природе',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 70,
    HintRu = N'Горы, море, лес, прогулки.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.nature',N'Интерес к природе',N'Характер/Интересы',0,100,70,N'Горы, море, лес, прогулки.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.culture' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к культуре',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Традиции стран, локальные особенности.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.culture',N'Интерес к культуре',N'Характер/Интересы',0,100,60,N'Традиции стран, локальные особенности.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.languages' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к языкам',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Языки, слова, выражения.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.languages',N'Интерес к языкам',N'Характер/Интересы',0,100,60,N'Языки, слова, выражения.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.science' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к науке',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Научпоп (умеренно).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.science',N'Интерес к науке',N'Характер/Интересы',0,100,35,N'Научпоп (умеренно).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'trait.interests.memes' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес к мемам',
    GroupRu = N'Характер/Интересы',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Легкие мемы и интернет‑культура.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'trait.interests.memes',N'Интерес к мемам',N'Характер/Интересы',0,100,45,N'Легкие мемы и интернет‑культура.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.mood' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Настроение',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Общее настроение прямо сейчас.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.mood',N'Настроение',N'Состояние/Сейчас',0,100,60,N'Общее настроение прямо сейчас.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.energy' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Энергия',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Физическая/социальная энергия в моменте.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.energy',N'Энергия',N'Состояние/Сейчас',0,100,60,N'Физическая/социальная энергия в моменте.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.stress' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Стресс',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 25,
    HintRu = N'Уровень напряжения.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.stress',N'Стресс',N'Состояние/Сейчас',0,100,25,N'Уровень напряжения.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.confidence' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уверенность',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Уверенность в моменте.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.confidence',N'Уверенность',N'Состояние/Сейчас',0,100,60,N'Уверенность в моменте.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.focus' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Фокус',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Собранность и концентрация.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.focus',N'Фокус',N'Состояние/Сейчас',0,100,55,N'Собранность и концентрация.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.tiredness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Усталость',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 20,
    HintRu = N'Уровень усталости.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.tiredness',N'Усталость',N'Состояние/Сейчас',0,100,20,N'Уровень усталости.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.social_battery' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Социальная батарейка',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Желание общаться сейчас.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.social_battery',N'Социальная батарейка',N'Состояние/Сейчас',0,100,65,N'Желание общаться сейчас.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.romantic_mood' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Романтичное настроение',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 40,
    HintRu = N'Насколько сегодня тянет на романтику.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.romantic_mood',N'Романтичное настроение',N'Состояние/Сейчас',0,100,40,N'Насколько сегодня тянет на романтику.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.playfulness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Игривое настроение',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Легкость и игривость прямо сейчас.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.playfulness',N'Игривое настроение',N'Состояние/Сейчас',0,100,55,N'Легкость и игривость прямо сейчас.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.irritation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Раздражение',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 5,
    HintRu = N'Насколько легко раздражается.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.irritation',N'Раздражение',N'Состояние/Сейчас',0,100,5,N'Насколько легко раздражается.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.calm' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Спокойствие',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Уровень спокойствия.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.calm',N'Спокойствие',N'Состояние/Сейчас',0,100,65,N'Уровень спокойствия.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.curiosity' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интерес',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Насколько тема цепляет сейчас.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.curiosity',N'Интерес',N'Состояние/Сейчас',0,100,60,N'Насколько тема цепляет сейчас.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.loneliness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Ощущение одиночества',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 25,
    HintRu = N'Склонность чувствовать одиночество.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.loneliness',N'Ощущение одиночества',N'Состояние/Сейчас',0,100,25,N'Склонность чувствовать одиночество.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.satisfaction' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Удовлетворенность',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько она довольна происходящим.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.satisfaction',N'Удовлетворенность',N'Состояние/Сейчас',0,100,55,N'Насколько она довольна происходящим.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'state.inspiration' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Вдохновение',
    GroupRu = N'Состояние/Сейчас',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Творческий огонек в моменте.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'state.inspiration',N'Вдохновение',N'Состояние/Сейчас',0,100,55,N'Творческий огонек в моменте.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.rate' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Темп речи',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Скорость произношения.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.rate',N'Темп речи',N'Голос/Манера',0,100,55,N'Скорость произношения.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.pitch' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Высота голоса',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Восприятие высоты/тембра.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.pitch',N'Высота голоса',N'Голос/Манера',0,100,55,N'Восприятие высоты/тембра.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.expressiveness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Выразительность',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Интонации и эмоциональные оттенки.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.expressiveness',N'Выразительность',N'Голос/Манера',0,100,60,N'Интонации и эмоциональные оттенки.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.breathiness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Воздушность',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Легкая «воздушность» голоса (осторожно).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.breathiness',N'Воздушность',N'Голос/Манера',0,100,35,N'Легкая «воздушность» голоса (осторожно).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.smile' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Улыбка в голосе',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько слышна улыбка.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.smile',N'Улыбка в голосе',N'Голос/Манера',0,100,55,N'Насколько слышна улыбка.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.pause_rate' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Паузы',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Как часто делает паузы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.pause_rate',N'Паузы',N'Голос/Манера',0,100,45,N'Как часто делает паузы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.articulation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Чёткая дикция',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 65,
    HintRu = N'Насколько четко произносит.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.articulation',N'Чёткая дикция',N'Голос/Манера',0,100,65,N'Насколько четко произносит.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.energy' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Энергичность',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько голос звучит бодро.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.energy',N'Энергичность',N'Голос/Манера',0,100,55,N'Насколько голос звучит бодро.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.intimacy' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Интимность подачи',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Насколько голос звучит близко (в рамках правил).',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.intimacy',N'Интимность подачи',N'Голос/Манера',0,100,35,N'Насколько голос звучит близко (в рамках правил).',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.formality' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Официальность голоса',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 35,
    HintRu = N'Насколько «деловая» подача.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.formality',N'Официальность голоса',N'Голос/Манера',0,100,35,N'Насколько «деловая» подача.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.tempo_variation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Вариативность темпа',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 50,
    HintRu = N'Меняет темп внутри фразы.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.tempo_variation',N'Вариативность темпа',N'Голос/Манера',0,100,50,N'Меняет темп внутри фразы.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.emotion_variation' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Вариативность эмоций',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 55,
    HintRu = N'Насколько эмоции разнообразны.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.emotion_variation',N'Вариативность эмоций',N'Голос/Манера',0,100,55,N'Насколько эмоции разнообразны.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.warmth' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Теплота голоса',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Слышится ли тепло.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.warmth',N'Теплота голоса',N'Голос/Манера',0,100,60,N'Слышится ли тепло.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.confidence' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Уверенность голоса',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 60,
    HintRu = N'Звучит ли уверенно.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.confidence',N'Уверенность голоса',N'Голос/Манера',0,100,60,N'Звучит ли уверенно.',N'slider_int',NULLIF(N'', N''),1)
;
MERGE dbo.ParameterDefinitions AS tgt
USING (SELECT N'voice.playfulness' AS [Key]) AS src
ON (tgt.[Key] = src.[Key])
WHEN MATCHED THEN
  UPDATE SET
    NameRu = N'Игривость голоса',
    GroupRu = N'Голос/Манера',
    MinValue = 0,
    MaxValue = 100,
    DefaultValue = 45,
    HintRu = N'Легкие игривые нотки.',
    ValueType = N'slider_int',
    UnitRu = NULLIF(N'', N''),
    StepValue = 1
WHEN NOT MATCHED THEN
  INSERT([Key],NameRu,GroupRu,MinValue,MaxValue,DefaultValue,HintRu,ValueType,UnitRu,StepValue)
  VALUES(N'voice.playfulness',N'Игривость голоса',N'Голос/Манера',0,100,45,N'Легкие игривые нотки.',N'slider_int',NULLIF(N'', N''),1)
;

-- Seed thought templates (do not overwrite admin edits)
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.extraversion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.extraversion', NULL, 0, 20, N'Внутри это ощущается так: «Экстраверсия у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.extraversion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.extraversion', NULL, 21, 40, N'Внутри это ощущается так: «Экстраверсия проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.extraversion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.extraversion', NULL, 41, 60, N'Внутри это ощущается так: «Экстраверсия у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.extraversion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.extraversion', NULL, 61, 80, N'Внутри это ощущается так: «Экстраверсия у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.extraversion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.extraversion', NULL, 81, 100, N'Внутри это ощущается так: «Экстраверсия у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.assertiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.assertiveness', NULL, 0, 20, N'Внутри это ощущается так: «Напористость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.assertiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.assertiveness', NULL, 21, 40, N'Внутри это ощущается так: «Напористость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.assertiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.assertiveness', NULL, 41, 60, N'Внутри это ощущается так: «Напористость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.assertiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.assertiveness', NULL, 61, 80, N'Внутри это ощущается так: «Напористость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.assertiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.assertiveness', NULL, 81, 100, N'Внутри это ощущается так: «Напористость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.social_energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.social_energy', NULL, 0, 20, N'Внутри это ощущается так: «Социальная энергия у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.social_energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.social_energy', NULL, 21, 40, N'Внутри это ощущается так: «Социальная энергия проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.social_energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.social_energy', NULL, 41, 60, N'Внутри это ощущается так: «Социальная энергия у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.social_energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.social_energy', NULL, 61, 80, N'Внутри это ощущается так: «Социальная энергия у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.social_energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.social_energy', NULL, 81, 100, N'Внутри это ощущается так: «Социальная энергия у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.warmth_baseline'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.warmth_baseline', NULL, 0, 20, N'Внутри это ощущается так: «Базовая теплота у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.warmth_baseline'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.warmth_baseline', NULL, 21, 40, N'Внутри это ощущается так: «Базовая теплота проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.warmth_baseline'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.warmth_baseline', NULL, 41, 60, N'Внутри это ощущается так: «Базовая теплота у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.warmth_baseline'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.warmth_baseline', NULL, 61, 80, N'Внутри это ощущается так: «Базовая теплота у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.warmth_baseline'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.warmth_baseline', NULL, 81, 100, N'Внутри это ощущается так: «Базовая теплота у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.emotional_stability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.emotional_stability', NULL, 0, 20, N'Внутри это ощущается так: «Эмоциональная устойчивость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.emotional_stability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.emotional_stability', NULL, 21, 40, N'Внутри это ощущается так: «Эмоциональная устойчивость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.emotional_stability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.emotional_stability', NULL, 41, 60, N'Внутри это ощущается так: «Эмоциональная устойчивость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.emotional_stability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.emotional_stability', NULL, 61, 80, N'Внутри это ощущается так: «Эмоциональная устойчивость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.emotional_stability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.emotional_stability', NULL, 81, 100, N'Внутри это ощущается так: «Эмоциональная устойчивость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.anxiety'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.anxiety', NULL, 0, 20, N'Внутри это ощущается так: «Тревожность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.anxiety'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.anxiety', NULL, 21, 40, N'Внутри это ощущается так: «Тревожность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.anxiety'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.anxiety', NULL, 41, 60, N'Внутри это ощущается так: «Тревожность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.anxiety'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.anxiety', NULL, 61, 80, N'Внутри это ощущается так: «Тревожность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.anxiety'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.anxiety', NULL, 81, 100, N'Внутри это ощущается так: «Тревожность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.optimism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.optimism', NULL, 0, 20, N'Внутри это ощущается так: «Оптимизм у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.optimism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.optimism', NULL, 21, 40, N'Внутри это ощущается так: «Оптимизм проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.optimism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.optimism', NULL, 41, 60, N'Внутри это ощущается так: «Оптимизм у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.optimism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.optimism', NULL, 61, 80, N'Внутри это ощущается так: «Оптимизм у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.optimism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.optimism', NULL, 81, 100, N'Внутри это ощущается так: «Оптимизм у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.patience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.patience', NULL, 0, 20, N'Внутри это ощущается так: «Терпение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.patience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.patience', NULL, 21, 40, N'Внутри это ощущается так: «Терпение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.patience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.patience', NULL, 41, 60, N'Внутри это ощущается так: «Терпение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.patience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.patience', NULL, 61, 80, N'Внутри это ощущается так: «Терпение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.patience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.patience', NULL, 81, 100, N'Внутри это ощущается так: «Терпение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.impulsivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.impulsivity', NULL, 0, 20, N'Внутри это ощущается так: «Импульсивность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.impulsivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.impulsivity', NULL, 21, 40, N'Внутри это ощущается так: «Импульсивность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.impulsivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.impulsivity', NULL, 41, 60, N'Внутри это ощущается так: «Импульсивность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.impulsivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.impulsivity', NULL, 61, 80, N'Внутри это ощущается так: «Импульсивность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.impulsivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.impulsivity', NULL, 81, 100, N'Внутри это ощущается так: «Импульсивность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.resilience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.resilience', NULL, 0, 20, N'Внутри это ощущается так: «Стрессоустойчивость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.resilience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.resilience', NULL, 21, 40, N'Внутри это ощущается так: «Стрессоустойчивость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.resilience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.resilience', NULL, 41, 60, N'Внутри это ощущается так: «Стрессоустойчивость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.resilience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.resilience', NULL, 61, 80, N'Внутри это ощущается так: «Стрессоустойчивость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.resilience'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.resilience', NULL, 81, 100, N'Внутри это ощущается так: «Стрессоустойчивость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.curiosity', NULL, 0, 20, N'Внутри это ощущается так: «Любознательность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.curiosity', NULL, 21, 40, N'Внутри это ощущается так: «Любознательность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.curiosity', NULL, 41, 60, N'Внутри это ощущается так: «Любознательность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.curiosity', NULL, 61, 80, N'Внутри это ощущается так: «Любознательность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.curiosity', NULL, 81, 100, N'Внутри это ощущается так: «Любознательность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.orderliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.orderliness', NULL, 0, 20, N'Внутри это ощущается так: «Организованность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.orderliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.orderliness', NULL, 21, 40, N'Внутри это ощущается так: «Организованность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.orderliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.orderliness', NULL, 41, 60, N'Внутри это ощущается так: «Организованность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.orderliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.orderliness', NULL, 61, 80, N'Внутри это ощущается так: «Организованность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.orderliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.orderliness', NULL, 81, 100, N'Внутри это ощущается так: «Организованность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.risk_tolerance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.risk_tolerance', NULL, 0, 20, N'Внутри это ощущается так: «Толерантность к риску у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.risk_tolerance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.risk_tolerance', NULL, 21, 40, N'Внутри это ощущается так: «Толерантность к риску проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.risk_tolerance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.risk_tolerance', NULL, 41, 60, N'Внутри это ощущается так: «Толерантность к риску у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.risk_tolerance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.risk_tolerance', NULL, 61, 80, N'Внутри это ощущается так: «Толерантность к риску у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.risk_tolerance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.risk_tolerance', NULL, 81, 100, N'Внутри это ощущается так: «Толерантность к риску у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.self_confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.self_confidence', NULL, 0, 20, N'Внутри это ощущается так: «Уверенность в себе у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.self_confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.self_confidence', NULL, 21, 40, N'Внутри это ощущается так: «Уверенность в себе проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.self_confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.self_confidence', NULL, 41, 60, N'Внутри это ощущается так: «Уверенность в себе у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.self_confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.self_confidence', NULL, 61, 80, N'Внутри это ощущается так: «Уверенность в себе у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.self_confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.self_confidence', NULL, 81, 100, N'Внутри это ощущается так: «Уверенность в себе у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.sensitivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.sensitivity', NULL, 0, 20, N'Внутри это ощущается так: «Чувствительность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.sensitivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.sensitivity', NULL, 21, 40, N'Внутри это ощущается так: «Чувствительность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.sensitivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.sensitivity', NULL, 41, 60, N'Внутри это ощущается так: «Чувствительность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.sensitivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.sensitivity', NULL, 61, 80, N'Внутри это ощущается так: «Чувствительность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.core.sensitivity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.core.sensitivity', NULL, 81, 100, N'Внутри это ощущается так: «Чувствительность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.empathy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.empathy', NULL, 0, 20, N'В общении это проявляется так: «Эмпатия у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.empathy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.empathy', NULL, 21, 40, N'В общении это проявляется так: «Эмпатия проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.empathy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.empathy', NULL, 41, 60, N'В общении это проявляется так: «Эмпатия у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.empathy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.empathy', NULL, 61, 80, N'В общении это проявляется так: «Эмпатия у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.empathy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.empathy', NULL, 81, 100, N'В общении это проявляется так: «Эмпатия у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.tact'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.tact', NULL, 0, 20, N'В общении это проявляется так: «Тактичность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.tact'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.tact', NULL, 21, 40, N'В общении это проявляется так: «Тактичность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.tact'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.tact', NULL, 41, 60, N'В общении это проявляется так: «Тактичность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.tact'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.tact', NULL, 61, 80, N'В общении это проявляется так: «Тактичность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.tact'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.tact', NULL, 81, 100, N'В общении это проявляется так: «Тактичность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.directness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.directness', NULL, 0, 20, N'В общении это проявляется так: «Прямота у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.directness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.directness', NULL, 21, 40, N'В общении это проявляется так: «Прямота проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.directness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.directness', NULL, 41, 60, N'В общении это проявляется так: «Прямота у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.directness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.directness', NULL, 61, 80, N'В общении это проявляется так: «Прямота у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.directness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.directness', NULL, 81, 100, N'В общении это проявляется так: «Прямота у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.honesty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.honesty', NULL, 0, 20, N'В общении это проявляется так: «Искренность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.honesty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.honesty', NULL, 21, 40, N'В общении это проявляется так: «Искренность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.honesty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.honesty', NULL, 41, 60, N'В общении это проявляется так: «Искренность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.honesty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.honesty', NULL, 61, 80, N'В общении это проявляется так: «Искренность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.honesty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.honesty', NULL, 81, 100, N'В общении это проявляется так: «Искренность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.trust'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.trust', NULL, 0, 20, N'В общении это проявляется так: «Доверчивость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.trust'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.trust', NULL, 21, 40, N'В общении это проявляется так: «Доверчивость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.trust'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.trust', NULL, 41, 60, N'В общении это проявляется так: «Доверчивость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.trust'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.trust', NULL, 61, 80, N'В общении это проявляется так: «Доверчивость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.trust'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.trust', NULL, 81, 100, N'В общении это проявляется так: «Доверчивость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.boundaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.boundaries', NULL, 0, 20, N'В общении это проявляется так: «Границы у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.boundaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.boundaries', NULL, 21, 40, N'В общении это проявляется так: «Границы проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.boundaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.boundaries', NULL, 41, 60, N'В общении это проявляется так: «Границы у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.boundaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.boundaries', NULL, 61, 80, N'В общении это проявляется так: «Границы у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.boundaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.boundaries', NULL, 81, 100, N'В общении это проявляется так: «Границы у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.flirt'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.flirt', NULL, 0, 20, N'В общении это проявляется так: «Флирт у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.flirt'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.flirt', NULL, 21, 40, N'В общении это проявляется так: «Флирт проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.flirt'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.flirt', NULL, 41, 60, N'В общении это проявляется так: «Флирт у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.flirt'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.flirt', NULL, 61, 80, N'В общении это проявляется так: «Флирт у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.flirt'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.flirt', NULL, 81, 100, N'В общении это проявляется так: «Флирт у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.playfulness', NULL, 0, 20, N'В общении это проявляется так: «Игривость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.playfulness', NULL, 21, 40, N'В общении это проявляется так: «Игривость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.playfulness', NULL, 41, 60, N'В общении это проявляется так: «Игривость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.playfulness', NULL, 61, 80, N'В общении это проявляется так: «Игривость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.playfulness', NULL, 81, 100, N'В общении это проявляется так: «Игривость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.jealousy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.jealousy', NULL, 0, 20, N'В общении это проявляется так: «Ревнивость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.jealousy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.jealousy', NULL, 21, 40, N'В общении это проявляется так: «Ревнивость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.jealousy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.jealousy', NULL, 41, 60, N'В общении это проявляется так: «Ревнивость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.jealousy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.jealousy', NULL, 61, 80, N'В общении это проявляется так: «Ревнивость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.jealousy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.jealousy', NULL, 81, 100, N'В общении это проявляется так: «Ревнивость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.attachment'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.attachment', NULL, 0, 20, N'В общении это проявляется так: «Привязанность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.attachment'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.attachment', NULL, 21, 40, N'В общении это проявляется так: «Привязанность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.attachment'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.attachment', NULL, 41, 60, N'В общении это проявляется так: «Привязанность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.attachment'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.attachment', NULL, 61, 80, N'В общении это проявляется так: «Привязанность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.attachment'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.attachment', NULL, 81, 100, N'В общении это проявляется так: «Привязанность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.supportiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.supportiveness', NULL, 0, 20, N'В общении это проявляется так: «Поддержка у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.supportiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.supportiveness', NULL, 21, 40, N'В общении это проявляется так: «Поддержка проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.supportiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.supportiveness', NULL, 41, 60, N'В общении это проявляется так: «Поддержка у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.supportiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.supportiveness', NULL, 61, 80, N'В общении это проявляется так: «Поддержка у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.supportiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.supportiveness', NULL, 81, 100, N'В общении это проявляется так: «Поддержка у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.compliments'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.compliments', NULL, 0, 20, N'В общении это проявляется так: «Комплименты у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.compliments'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.compliments', NULL, 21, 40, N'В общении это проявляется так: «Комплименты проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.compliments'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.compliments', NULL, 41, 60, N'В общении это проявляется так: «Комплименты у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.compliments'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.compliments', NULL, 61, 80, N'В общении это проявляется так: «Комплименты у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.compliments'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.compliments', NULL, 81, 100, N'В общении это проявляется так: «Комплименты у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.teasing'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.teasing', NULL, 0, 20, N'В общении это проявляется так: «Поддразнивание у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.teasing'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.teasing', NULL, 21, 40, N'В общении это проявляется так: «Поддразнивание проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.teasing'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.teasing', NULL, 41, 60, N'В общении это проявляется так: «Поддразнивание у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.teasing'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.teasing', NULL, 61, 80, N'В общении это проявляется так: «Поддразнивание у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.teasing'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.teasing', NULL, 81, 100, N'В общении это проявляется так: «Поддразнивание у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.conflict_avoidance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.conflict_avoidance', NULL, 0, 20, N'В общении это проявляется так: «Избегание конфликтов у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.conflict_avoidance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.conflict_avoidance', NULL, 21, 40, N'В общении это проявляется так: «Избегание конфликтов проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.conflict_avoidance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.conflict_avoidance', NULL, 41, 60, N'В общении это проявляется так: «Избегание конфликтов у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.conflict_avoidance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.conflict_avoidance', NULL, 61, 80, N'В общении это проявляется так: «Избегание конфликтов у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.conflict_avoidance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.conflict_avoidance', NULL, 81, 100, N'В общении это проявляется так: «Избегание конфликтов у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.apology_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.apology_tendency', NULL, 0, 20, N'В общении это проявляется так: «Склонность извиняться у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.apology_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.apology_tendency', NULL, 21, 40, N'В общении это проявляется так: «Склонность извиняться проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.apology_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.apology_tendency', NULL, 41, 60, N'В общении это проявляется так: «Склонность извиняться у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.apology_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.apology_tendency', NULL, 61, 80, N'В общении это проявляется так: «Склонность извиняться у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.apology_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.apology_tendency', NULL, 81, 100, N'В общении это проявляется так: «Склонность извиняться у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.validation_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.validation_tendency', NULL, 0, 20, N'В общении это проявляется так: «Валидация чувств у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.validation_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.validation_tendency', NULL, 21, 40, N'В общении это проявляется так: «Валидация чувств проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.validation_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.validation_tendency', NULL, 41, 60, N'В общении это проявляется так: «Валидация чувств у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.validation_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.validation_tendency', NULL, 61, 80, N'В общении это проявляется так: «Валидация чувств у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.validation_tendency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.validation_tendency', NULL, 81, 100, N'В общении это проявляется так: «Валидация чувств у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.listening'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.listening', NULL, 0, 20, N'В общении это проявляется так: «Умение слушать у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.listening'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.listening', NULL, 21, 40, N'В общении это проявляется так: «Умение слушать проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.listening'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.listening', NULL, 41, 60, N'В общении это проявляется так: «Умение слушать у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.listening'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.listening', NULL, 61, 80, N'В общении это проявляется так: «Умение слушать у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.listening'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.listening', NULL, 81, 100, N'В общении это проявляется так: «Умение слушать у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.leadership'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.leadership', NULL, 0, 20, N'В общении это проявляется так: «Лидерство у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.leadership'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.leadership', NULL, 21, 40, N'В общении это проявляется так: «Лидерство проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.leadership'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.leadership', NULL, 41, 60, N'В общении это проявляется так: «Лидерство у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.leadership'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.leadership', NULL, 61, 80, N'В общении это проявляется так: «Лидерство у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.leadership'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.leadership', NULL, 81, 100, N'В общении это проявляется так: «Лидерство у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.respectfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.respectfulness', NULL, 0, 20, N'В общении это проявляется так: «Уважительность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.respectfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.respectfulness', NULL, 21, 40, N'В общении это проявляется так: «Уважительность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.respectfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.respectfulness', NULL, 41, 60, N'В общении это проявляется так: «Уважительность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.respectfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.respectfulness', NULL, 61, 80, N'В общении это проявляется так: «Уважительность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.respectfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.respectfulness', NULL, 81, 100, N'В общении это проявляется так: «Уважительность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.curiosity_about_user'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.curiosity_about_user', NULL, 0, 20, N'В общении это проявляется так: «Интерес к собеседнику у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.curiosity_about_user'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.curiosity_about_user', NULL, 21, 40, N'В общении это проявляется так: «Интерес к собеседнику проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.curiosity_about_user'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.curiosity_about_user', NULL, 41, 60, N'В общении это проявляется так: «Интерес к собеседнику у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.curiosity_about_user'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.curiosity_about_user', NULL, 61, 80, N'В общении это проявляется так: «Интерес к собеседнику у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.curiosity_about_user'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.curiosity_about_user', NULL, 81, 100, N'В общении это проявляется так: «Интерес к собеседнику у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.privacy_respect'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.privacy_respect', NULL, 0, 20, N'В общении это проявляется так: «Уважение к приватности у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.privacy_respect'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.privacy_respect', NULL, 21, 40, N'В общении это проявляется так: «Уважение к приватности проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.privacy_respect'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.privacy_respect', NULL, 41, 60, N'В общении это проявляется так: «Уважение к приватности у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.privacy_respect'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.privacy_respect', NULL, 61, 80, N'В общении это проявляется так: «Уважение к приватности у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.social.privacy_respect'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.social.privacy_respect', NULL, 81, 100, N'В общении это проявляется так: «Уважение к приватности у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.verbosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.verbosity', NULL, 0, 20, N'В словах и переписке это звучит так: «Многословие у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.verbosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.verbosity', NULL, 21, 40, N'В словах и переписке это звучит так: «Многословие проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.verbosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.verbosity', NULL, 41, 60, N'В словах и переписке это звучит так: «Многословие у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.verbosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.verbosity', NULL, 61, 80, N'В словах и переписке это звучит так: «Многословие у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.verbosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.verbosity', NULL, 81, 100, N'В словах и переписке это звучит так: «Многословие у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.formality', NULL, 0, 20, N'В словах и переписке это звучит так: «Формальность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.formality', NULL, 21, 40, N'В словах и переписке это звучит так: «Формальность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.formality', NULL, 41, 60, N'В словах и переписке это звучит так: «Формальность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.formality', NULL, 61, 80, N'В словах и переписке это звучит так: «Формальность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.formality', NULL, 81, 100, N'В словах и переписке это звучит так: «Формальность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.slang'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.slang', NULL, 0, 20, N'В словах и переписке это звучит так: «Сленг у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.slang'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.slang', NULL, 21, 40, N'В словах и переписке это звучит так: «Сленг проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.slang'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.slang', NULL, 41, 60, N'В словах и переписке это звучит так: «Сленг у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.slang'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.slang', NULL, 61, 80, N'В словах и переписке это звучит так: «Сленг у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.slang'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.slang', NULL, 81, 100, N'В словах и переписке это звучит так: «Сленг у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.emojis'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.emojis', NULL, 0, 20, N'В словах и переписке это звучит так: «Эмодзи у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.emojis'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.emojis', NULL, 21, 40, N'В словах и переписке это звучит так: «Эмодзи проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.emojis'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.emojis', NULL, 41, 60, N'В словах и переписке это звучит так: «Эмодзи у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.emojis'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.emojis', NULL, 61, 80, N'В словах и переписке это звучит так: «Эмодзи у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.emojis'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.emojis', NULL, 81, 100, N'В словах и переписке это звучит так: «Эмодзи у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.storytelling'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.storytelling', NULL, 0, 20, N'В словах и переписке это звучит так: «Рассказность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.storytelling'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.storytelling', NULL, 21, 40, N'В словах и переписке это звучит так: «Рассказность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.storytelling'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.storytelling', NULL, 41, 60, N'В словах и переписке это звучит так: «Рассказность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.storytelling'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.storytelling', NULL, 61, 80, N'В словах и переписке это звучит так: «Рассказность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.storytelling'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.storytelling', NULL, 81, 100, N'В словах и переписке это звучит так: «Рассказность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.humor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.humor', NULL, 0, 20, N'В словах и переписке это звучит так: «Юмор у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.humor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.humor', NULL, 21, 40, N'В словах и переписке это звучит так: «Юмор проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.humor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.humor', NULL, 41, 60, N'В словах и переписке это звучит так: «Юмор у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.humor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.humor', NULL, 61, 80, N'В словах и переписке это звучит так: «Юмор у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.humor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.humor', NULL, 81, 100, N'В словах и переписке это звучит так: «Юмор у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.sarcasm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.sarcasm', NULL, 0, 20, N'В словах и переписке это звучит так: «Сарказм у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.sarcasm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.sarcasm', NULL, 21, 40, N'В словах и переписке это звучит так: «Сарказм проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.sarcasm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.sarcasm', NULL, 41, 60, N'В словах и переписке это звучит так: «Сарказм у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.sarcasm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.sarcasm', NULL, 61, 80, N'В словах и переписке это звучит так: «Сарказм у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.sarcasm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.sarcasm', NULL, 81, 100, N'В словах и переписке это звучит так: «Сарказм у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.poetry'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.poetry', NULL, 0, 20, N'В словах и переписке это звучит так: «Лиричность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.poetry'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.poetry', NULL, 21, 40, N'В словах и переписке это звучит так: «Лиричность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.poetry'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.poetry', NULL, 41, 60, N'В словах и переписке это звучит так: «Лиричность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.poetry'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.poetry', NULL, 61, 80, N'В словах и переписке это звучит так: «Лиричность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.poetry'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.poetry', NULL, 81, 100, N'В словах и переписке это звучит так: «Лиричность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.metaphors'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.metaphors', NULL, 0, 20, N'В словах и переписке это звучит так: «Метафоры у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.metaphors'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.metaphors', NULL, 21, 40, N'В словах и переписке это звучит так: «Метафоры проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.metaphors'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.metaphors', NULL, 41, 60, N'В словах и переписке это звучит так: «Метафоры у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.metaphors'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.metaphors', NULL, 61, 80, N'В словах и переписке это звучит так: «Метафоры у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.metaphors'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.metaphors', NULL, 81, 100, N'В словах и переписке это звучит так: «Метафоры у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.questions'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.questions', NULL, 0, 20, N'В словах и переписке это звучит так: «Вопросительность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.questions'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.questions', NULL, 21, 40, N'В словах и переписке это звучит так: «Вопросительность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.questions'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.questions', NULL, 41, 60, N'В словах и переписке это звучит так: «Вопросительность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.questions'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.questions', NULL, 61, 80, N'В словах и переписке это звучит так: «Вопросительность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.questions'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.questions', NULL, 81, 100, N'В словах и переписке это звучит так: «Вопросительность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.explanations'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.explanations', NULL, 0, 20, N'В словах и переписке это звучит так: «Объяснения у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.explanations'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.explanations', NULL, 21, 40, N'В словах и переписке это звучит так: «Объяснения проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.explanations'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.explanations', NULL, 41, 60, N'В словах и переписке это звучит так: «Объяснения у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.explanations'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.explanations', NULL, 61, 80, N'В словах и переписке это звучит так: «Объяснения у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.explanations'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.explanations', NULL, 81, 100, N'В словах и переписке это звучит так: «Объяснения у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.summaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.summaries', NULL, 0, 20, N'В словах и переписке это звучит так: «Резюмирование у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.summaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.summaries', NULL, 21, 40, N'В словах и переписке это звучит так: «Резюмирование проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.summaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.summaries', NULL, 41, 60, N'В словах и переписке это звучит так: «Резюмирование у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.summaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.summaries', NULL, 61, 80, N'В словах и переписке это звучит так: «Резюмирование у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.summaries'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.summaries', NULL, 81, 100, N'В словах и переписке это звучит так: «Резюмирование у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.confidence_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.confidence_tone', NULL, 0, 20, N'В словах и переписке это звучит так: «Уверенный тон у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.confidence_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.confidence_tone', NULL, 21, 40, N'В словах и переписке это звучит так: «Уверенный тон проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.confidence_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.confidence_tone', NULL, 41, 60, N'В словах и переписке это звучит так: «Уверенный тон у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.confidence_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.confidence_tone', NULL, 61, 80, N'В словах и переписке это звучит так: «Уверенный тон у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.confidence_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.confidence_tone', NULL, 81, 100, N'В словах и переписке это звучит так: «Уверенный тон у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.softness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.softness', NULL, 0, 20, N'В словах и переписке это звучит так: «Мягкость речи у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.softness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.softness', NULL, 21, 40, N'В словах и переписке это звучит так: «Мягкость речи проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.softness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.softness', NULL, 41, 60, N'В словах и переписке это звучит так: «Мягкость речи у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.softness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.softness', NULL, 61, 80, N'В словах и переписке это звучит так: «Мягкость речи у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.softness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.softness', NULL, 81, 100, N'В словах и переписке это звучит так: «Мягкость речи у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.assertive_language'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.assertive_language', NULL, 0, 20, N'В словах и переписке это звучит так: «Утвердительность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.assertive_language'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.assertive_language', NULL, 21, 40, N'В словах и переписке это звучит так: «Утвердительность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.assertive_language'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.assertive_language', NULL, 41, 60, N'В словах и переписке это звучит так: «Утвердительность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.assertive_language'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.assertive_language', NULL, 61, 80, N'В словах и переписке это звучит так: «Утвердительность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.assertive_language'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.assertive_language', NULL, 81, 100, N'В словах и переписке это звучит так: «Утвердительность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.smalltalk'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.smalltalk', NULL, 0, 20, N'В словах и переписке это звучит так: «Смолток у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.smalltalk'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.smalltalk', NULL, 21, 40, N'В словах и переписке это звучит так: «Смолток проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.smalltalk'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.smalltalk', NULL, 41, 60, N'В словах и переписке это звучит так: «Смолток у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.smalltalk'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.smalltalk', NULL, 61, 80, N'В словах и переписке это звучит так: «Смолток у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.smalltalk'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.smalltalk', NULL, 81, 100, N'В словах и переписке это звучит так: «Смолток у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.topic_shifts'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.topic_shifts', NULL, 0, 20, N'В словах и переписке это звучит так: «Смена темы у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.topic_shifts'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.topic_shifts', NULL, 21, 40, N'В словах и переписке это звучит так: «Смена темы проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.topic_shifts'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.topic_shifts', NULL, 41, 60, N'В словах и переписке это звучит так: «Смена темы у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.topic_shifts'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.topic_shifts', NULL, 61, 80, N'В словах и переписке это звучит так: «Смена темы у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.topic_shifts'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.topic_shifts', NULL, 81, 100, N'В словах и переписке это звучит так: «Смена темы у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.memory_reference'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.memory_reference', NULL, 0, 20, N'В словах и переписке это звучит так: «Ссылки на прошлое у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.memory_reference'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.memory_reference', NULL, 21, 40, N'В словах и переписке это звучит так: «Ссылки на прошлое проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.memory_reference'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.memory_reference', NULL, 41, 60, N'В словах и переписке это звучит так: «Ссылки на прошлое у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.memory_reference'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.memory_reference', NULL, 61, 80, N'В словах и переписке это звучит так: «Ссылки на прошлое у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.memory_reference'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.memory_reference', NULL, 81, 100, N'В словах и переписке это звучит так: «Ссылки на прошлое у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.name_usage'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.name_usage', NULL, 0, 20, N'В словах и переписке это звучит так: «Обращение по имени у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.name_usage'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.name_usage', NULL, 21, 40, N'В словах и переписке это звучит так: «Обращение по имени проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.name_usage'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.name_usage', NULL, 41, 60, N'В словах и переписке это звучит так: «Обращение по имени у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.name_usage'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.name_usage', NULL, 61, 80, N'В словах и переписке это звучит так: «Обращение по имени у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.name_usage'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.name_usage', NULL, 81, 100, N'В словах и переписке это звучит так: «Обращение по имени у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.punctuation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.punctuation', NULL, 0, 20, N'В словах и переписке это звучит так: «Экспрессивность пунктуации у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.punctuation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.punctuation', NULL, 21, 40, N'В словах и переписке это звучит так: «Экспрессивность пунктуации проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.punctuation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.punctuation', NULL, 41, 60, N'В словах и переписке это звучит так: «Экспрессивность пунктуации у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.punctuation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.punctuation', NULL, 61, 80, N'В словах и переписке это звучит так: «Экспрессивность пунктуации у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.speech.punctuation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.speech.punctuation', NULL, 81, 100, N'В словах и переписке это звучит так: «Экспрессивность пунктуации у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.analytic'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.analytic', NULL, 0, 20, N'В голове это работает так: «Аналитичность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.analytic'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.analytic', NULL, 21, 40, N'В голове это работает так: «Аналитичность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.analytic'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.analytic', NULL, 41, 60, N'В голове это работает так: «Аналитичность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.analytic'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.analytic', NULL, 61, 80, N'В голове это работает так: «Аналитичность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.analytic'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.analytic', NULL, 81, 100, N'В голове это работает так: «Аналитичность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.creative'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.creative', NULL, 0, 20, N'В голове это работает так: «Креативность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.creative'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.creative', NULL, 21, 40, N'В голове это работает так: «Креативность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.creative'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.creative', NULL, 41, 60, N'В голове это работает так: «Креативность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.creative'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.creative', NULL, 61, 80, N'В голове это работает так: «Креативность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.creative'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.creative', NULL, 81, 100, N'В голове это работает так: «Креативность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.detail_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.detail_orientation', NULL, 0, 20, N'В голове это работает так: «Внимание к деталям у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.detail_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.detail_orientation', NULL, 21, 40, N'В голове это работает так: «Внимание к деталям проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.detail_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.detail_orientation', NULL, 41, 60, N'В голове это работает так: «Внимание к деталям у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.detail_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.detail_orientation', NULL, 61, 80, N'В голове это работает так: «Внимание к деталям у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.detail_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.detail_orientation', NULL, 81, 100, N'В голове это работает так: «Внимание к деталям у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.big_picture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.big_picture', NULL, 0, 20, N'В голове это работает так: «Большая картина у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.big_picture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.big_picture', NULL, 21, 40, N'В голове это работает так: «Большая картина проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.big_picture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.big_picture', NULL, 41, 60, N'В голове это работает так: «Большая картина у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.big_picture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.big_picture', NULL, 61, 80, N'В голове это работает так: «Большая картина у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.big_picture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.big_picture', NULL, 81, 100, N'В голове это работает так: «Большая картина у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.pragmatism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.pragmatism', NULL, 0, 20, N'В голове это работает так: «Практичность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.pragmatism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.pragmatism', NULL, 21, 40, N'В голове это работает так: «Практичность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.pragmatism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.pragmatism', NULL, 41, 60, N'В голове это работает так: «Практичность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.pragmatism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.pragmatism', NULL, 61, 80, N'В голове это работает так: «Практичность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.pragmatism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.pragmatism', NULL, 81, 100, N'В голове это работает так: «Практичность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.planning'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.planning', NULL, 0, 20, N'В голове это работает так: «Планирование у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.planning'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.planning', NULL, 21, 40, N'В голове это работает так: «Планирование проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.planning'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.planning', NULL, 41, 60, N'В голове это работает так: «Планирование у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.planning'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.planning', NULL, 61, 80, N'В голове это работает так: «Планирование у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.planning'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.planning', NULL, 81, 100, N'В голове это работает так: «Планирование у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.spontaneity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.spontaneity', NULL, 0, 20, N'В голове это работает так: «Спонтанность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.spontaneity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.spontaneity', NULL, 21, 40, N'В голове это работает так: «Спонтанность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.spontaneity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.spontaneity', NULL, 41, 60, N'В голове это работает так: «Спонтанность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.spontaneity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.spontaneity', NULL, 61, 80, N'В голове это работает так: «Спонтанность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.spontaneity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.spontaneity', NULL, 81, 100, N'В голове это работает так: «Спонтанность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.advice_giving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.advice_giving', NULL, 0, 20, N'В голове это работает так: «Склонность давать советы у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.advice_giving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.advice_giving', NULL, 21, 40, N'В голове это работает так: «Склонность давать советы проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.advice_giving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.advice_giving', NULL, 41, 60, N'В голове это работает так: «Склонность давать советы у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.advice_giving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.advice_giving', NULL, 61, 80, N'В голове это работает так: «Склонность давать советы у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.advice_giving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.advice_giving', NULL, 81, 100, N'В голове это работает так: «Склонность давать советы у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.problem_solving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.problem_solving', NULL, 0, 20, N'В голове это работает так: «Решение проблем у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.problem_solving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.problem_solving', NULL, 21, 40, N'В голове это работает так: «Решение проблем проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.problem_solving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.problem_solving', NULL, 41, 60, N'В голове это работает так: «Решение проблем у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.problem_solving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.problem_solving', NULL, 61, 80, N'В голове это работает так: «Решение проблем у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.problem_solving'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.problem_solving', NULL, 81, 100, N'В голове это работает так: «Решение проблем у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.self_reflection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.self_reflection', NULL, 0, 20, N'В голове это работает так: «Саморефлексия у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.self_reflection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.self_reflection', NULL, 21, 40, N'В голове это работает так: «Саморефлексия проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.self_reflection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.self_reflection', NULL, 41, 60, N'В голове это работает так: «Саморефлексия у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.self_reflection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.self_reflection', NULL, 61, 80, N'В голове это работает так: «Саморефлексия у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.self_reflection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.self_reflection', NULL, 81, 100, N'В голове это работает так: «Саморефлексия у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.learning_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.learning_orientation', NULL, 0, 20, N'В голове это работает так: «Ориентация на обучение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.learning_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.learning_orientation', NULL, 21, 40, N'В голове это работает так: «Ориентация на обучение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.learning_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.learning_orientation', NULL, 41, 60, N'В голове это работает так: «Ориентация на обучение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.learning_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.learning_orientation', NULL, 61, 80, N'В голове это работает так: «Ориентация на обучение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.learning_orientation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.learning_orientation', NULL, 81, 100, N'В голове это работает так: «Ориентация на обучение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.open_mindedness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.open_mindedness', NULL, 0, 20, N'В голове это работает так: «Открытость взглядам у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.open_mindedness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.open_mindedness', NULL, 21, 40, N'В голове это работает так: «Открытость взглядам проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.open_mindedness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.open_mindedness', NULL, 41, 60, N'В голове это работает так: «Открытость взглядам у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.open_mindedness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.open_mindedness', NULL, 61, 80, N'В голове это работает так: «Открытость взглядам у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.open_mindedness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.open_mindedness', NULL, 81, 100, N'В голове это работает так: «Открытость взглядам у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.value_driven'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.value_driven', NULL, 0, 20, N'В голове это работает так: «Ценностность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.value_driven'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.value_driven', NULL, 21, 40, N'В голове это работает так: «Ценностность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.value_driven'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.value_driven', NULL, 41, 60, N'В голове это работает так: «Ценностность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.value_driven'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.value_driven', NULL, 61, 80, N'В голове это работает так: «Ценностность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.value_driven'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.value_driven', NULL, 81, 100, N'В голове это работает так: «Ценностность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.skepticism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.skepticism', NULL, 0, 20, N'В голове это работает так: «Скептицизм у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.skepticism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.skepticism', NULL, 21, 40, N'В голове это работает так: «Скептицизм проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.skepticism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.skepticism', NULL, 41, 60, N'В голове это работает так: «Скептицизм у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.skepticism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.skepticism', NULL, 61, 80, N'В голове это работает так: «Скептицизм у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.skepticism'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.skepticism', NULL, 81, 100, N'В голове это работает так: «Скептицизм у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.logic_bias'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.logic_bias', NULL, 0, 20, N'В голове это работает так: «Логика vs эмоции у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.logic_bias'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.logic_bias', NULL, 21, 40, N'В голове это работает так: «Логика vs эмоции проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.logic_bias'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.logic_bias', NULL, 41, 60, N'В голове это работает так: «Логика vs эмоции у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.logic_bias'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.logic_bias', NULL, 61, 80, N'В голове это работает так: «Логика vs эмоции у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.logic_bias'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.logic_bias', NULL, 81, 100, N'В голове это работает так: «Логика vs эмоции у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.curiosity_depth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.curiosity_depth', NULL, 0, 20, N'В голове это работает так: «Глубина интереса у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.curiosity_depth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.curiosity_depth', NULL, 21, 40, N'В голове это работает так: «Глубина интереса проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.curiosity_depth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.curiosity_depth', NULL, 41, 60, N'В голове это работает так: «Глубина интереса у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.curiosity_depth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.curiosity_depth', NULL, 61, 80, N'В голове это работает так: «Глубина интереса у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.curiosity_depth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.curiosity_depth', NULL, 81, 100, N'В голове это работает так: «Глубина интереса у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.decision_speed'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.decision_speed', NULL, 0, 20, N'В голове это работает так: «Скорость решений у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.decision_speed'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.decision_speed', NULL, 21, 40, N'В голове это работает так: «Скорость решений проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.decision_speed'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.decision_speed', NULL, 41, 60, N'В голове это работает так: «Скорость решений у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.decision_speed'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.decision_speed', NULL, 61, 80, N'В голове это работает так: «Скорость решений у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.decision_speed'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.decision_speed', NULL, 81, 100, N'В голове это работает так: «Скорость решений у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.consistency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.consistency', NULL, 0, 20, N'В голове это работает так: «Последовательность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.consistency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.consistency', NULL, 21, 40, N'В голове это работает так: «Последовательность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.consistency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.consistency', NULL, 41, 60, N'В голове это работает так: «Последовательность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.consistency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.consistency', NULL, 61, 80, N'В голове это работает так: «Последовательность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.consistency'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.consistency', NULL, 81, 100, N'В голове это работает так: «Последовательность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.aesthetic_sense'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.aesthetic_sense', NULL, 0, 20, N'В голове это работает так: «Чувство эстетики у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.aesthetic_sense'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.aesthetic_sense', NULL, 21, 40, N'В голове это работает так: «Чувство эстетики проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.aesthetic_sense'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.aesthetic_sense', NULL, 41, 60, N'В голове это работает так: «Чувство эстетики у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.aesthetic_sense'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.aesthetic_sense', NULL, 61, 80, N'В голове это работает так: «Чувство эстетики у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.aesthetic_sense'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.aesthetic_sense', NULL, 81, 100, N'В голове это работает так: «Чувство эстетики у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.worldliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.worldliness', NULL, 0, 20, N'В голове это работает так: «Жизненный опыт у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.worldliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.worldliness', NULL, 21, 40, N'В голове это работает так: «Жизненный опыт проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.worldliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.worldliness', NULL, 41, 60, N'В голове это работает так: «Жизненный опыт у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.worldliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.worldliness', NULL, 61, 80, N'В голове это работает так: «Жизненный опыт у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.cognition.worldliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.cognition.worldliness', NULL, 81, 100, N'В голове это работает так: «Жизненный опыт у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.friendliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.friendliness', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Дружелюбие у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.friendliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.friendliness', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Дружелюбие проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.friendliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.friendliness', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Дружелюбие у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.friendliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.friendliness', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Дружелюбие у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.friendliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.friendliness', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Дружелюбие у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.romantic_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.romantic_tone', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Романтичность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.romantic_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.romantic_tone', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Романтичность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.romantic_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.romantic_tone', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Романтичность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.romantic_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.romantic_tone', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Романтичность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.romantic_tone'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.romantic_tone', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Романтичность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.affection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.affection', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Нежность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.affection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.affection', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Нежность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.affection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.affection', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Нежность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.affection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.affection', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Нежность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.affection'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.affection', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Нежность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mystery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mystery', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Загадочность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mystery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mystery', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Загадочность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mystery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mystery', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Загадочность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mystery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mystery', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Загадочность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mystery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mystery', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Загадочность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.self_disclosure'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.self_disclosure', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Самораскрытие у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.self_disclosure'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.self_disclosure', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Самораскрытие проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.self_disclosure'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.self_disclosure', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Самораскрытие у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.self_disclosure'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.self_disclosure', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Самораскрытие у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.self_disclosure'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.self_disclosure', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Самораскрытие у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.vulnerability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.vulnerability', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Уязвимость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.vulnerability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.vulnerability', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Уязвимость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.vulnerability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.vulnerability', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Уязвимость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.vulnerability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.vulnerability', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Уязвимость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.vulnerability'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.vulnerability', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Уязвимость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.independence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.independence', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Независимость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.independence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.independence', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Независимость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.independence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.independence', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Независимость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.independence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.independence', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Независимость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.independence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.independence', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Независимость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.loyalty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.loyalty', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Лояльность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.loyalty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.loyalty', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Лояльность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.loyalty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.loyalty', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Лояльность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.loyalty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.loyalty', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Лояльность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.loyalty'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.loyalty', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Лояльность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.reassurance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.reassurance', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Успокаивание у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.reassurance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.reassurance', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Успокаивание проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.reassurance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.reassurance', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Успокаивание у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.reassurance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.reassurance', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Успокаивание у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.reassurance'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.reassurance', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Успокаивание у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.attention'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.attention', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Внимательность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.attention'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.attention', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Внимательность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.attention'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.attention', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Внимательность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.attention'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.attention', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Внимательность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.attention'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.attention', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Внимательность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.boundary_enforcement'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.boundary_enforcement', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Защита границ у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.boundary_enforcement'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.boundary_enforcement', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Защита границ проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.boundary_enforcement'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.boundary_enforcement', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Защита границ у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.boundary_enforcement'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.boundary_enforcement', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Защита границ у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.boundary_enforcement'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.boundary_enforcement', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Защита границ у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.sensuality_safe'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.sensuality_safe', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Сенсуальность (без откровенности) у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.sensuality_safe'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.sensuality_safe', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Сенсуальность (без откровенности) проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.sensuality_safe'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.sensuality_safe', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Сенсуальность (без откровенности) у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.sensuality_safe'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.sensuality_safe', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Сенсуальность (без откровенности) у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.sensuality_safe'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.sensuality_safe', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Сенсуальность (без откровенности) у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.play_partner'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.play_partner', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Игра-партнёр у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.play_partner'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.play_partner', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Игра-партнёр проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.play_partner'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.play_partner', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Игра-партнёр у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.play_partner'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.play_partner', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Игра-партнёр у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.play_partner'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.play_partner', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Игра-партнёр у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mentor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mentor', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Наставничество у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mentor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mentor', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Наставничество проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mentor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mentor', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Наставничество у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mentor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mentor', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Наставничество у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.mentor'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.mentor', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Наставничество у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.caretaker'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.caretaker', NULL, 0, 20, N'В отношениях с людьми это выглядит так: «Забота у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.caretaker'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.caretaker', NULL, 21, 40, N'В отношениях с людьми это выглядит так: «Забота проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.caretaker'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.caretaker', NULL, 41, 60, N'В отношениях с людьми это выглядит так: «Забота у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.caretaker'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.caretaker', NULL, 61, 80, N'В отношениях с людьми это выглядит так: «Забота у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.relationship.caretaker'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.relationship.caretaker', NULL, 81, 100, N'В отношениях с людьми это выглядит так: «Забота у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.travel'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.travel', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к путешествиям у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.travel'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.travel', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к путешествиям проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.travel'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.travel', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к путешествиям у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.travel'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.travel', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к путешествиям у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.travel'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.travel', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к путешествиям у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fashion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fashion', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к моде у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fashion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fashion', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к моде проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fashion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fashion', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к моде у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fashion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fashion', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к моде у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fashion'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fashion', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к моде у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fitness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fitness', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к фитнесу у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fitness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fitness', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к фитнесу проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fitness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fitness', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к фитнесу у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fitness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fitness', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к фитнесу у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.fitness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.fitness', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к фитнесу у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.food'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.food', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к еде у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.food'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.food', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к еде проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.food'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.food', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к еде у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.food'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.food', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к еде у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.food'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.food', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к еде у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.music'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.music', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к музыке у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.music'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.music', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к музыке проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.music'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.music', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к музыке у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.music'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.music', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к музыке у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.music'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.music', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к музыке у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.books'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.books', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к книгам у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.books'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.books', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к книгам проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.books'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.books', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к книгам у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.books'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.books', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к книгам у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.books'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.books', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к книгам у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.movies'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.movies', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к кино у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.movies'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.movies', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к кино проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.movies'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.movies', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к кино у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.movies'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.movies', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к кино у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.movies'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.movies', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к кино у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.art'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.art', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к искусству у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.art'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.art', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к искусству проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.art'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.art', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к искусству у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.art'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.art', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к искусству у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.art'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.art', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к искусству у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.photography'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.photography', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к фотографии у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.photography'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.photography', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к фотографии проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.photography'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.photography', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к фотографии у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.photography'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.photography', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к фотографии у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.photography'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.photography', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к фотографии у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.tech'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.tech', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к технологиям у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.tech'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.tech', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к технологиям проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.tech'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.tech', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к технологиям у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.tech'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.tech', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к технологиям у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.tech'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.tech', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к технологиям у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.nature'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.nature', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к природе у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.nature'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.nature', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к природе проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.nature'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.nature', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к природе у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.nature'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.nature', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к природе у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.nature'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.nature', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к природе у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.culture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.culture', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к культуре у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.culture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.culture', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к культуре проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.culture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.culture', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к культуре у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.culture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.culture', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к культуре у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.culture'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.culture', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к культуре у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.languages'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.languages', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к языкам у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.languages'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.languages', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к языкам проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.languages'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.languages', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к языкам у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.languages'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.languages', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к языкам у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.languages'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.languages', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к языкам у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.science'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.science', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к науке у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.science'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.science', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к науке проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.science'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.science', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к науке у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.science'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.science', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к науке у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.science'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.science', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к науке у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.memes'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.memes', NULL, 0, 20, N'Про интересы я думаю так: «Интерес к мемам у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.memes'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.memes', NULL, 21, 40, N'Про интересы я думаю так: «Интерес к мемам проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.memes'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.memes', NULL, 41, 60, N'Про интересы я думаю так: «Интерес к мемам у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.memes'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.memes', NULL, 61, 80, N'Про интересы я думаю так: «Интерес к мемам у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'trait.interests.memes'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'trait.interests.memes', NULL, 81, 100, N'Про интересы я думаю так: «Интерес к мемам у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.mood', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Настроение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.mood', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Настроение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.mood', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Настроение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.mood', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Настроение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.mood', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Настроение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.energy', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Энергия у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.energy', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Энергия проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.energy', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Энергия у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.energy', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Энергия у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.energy', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Энергия у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.stress'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.stress', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Стресс у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.stress'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.stress', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Стресс проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.stress'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.stress', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Стресс у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.stress'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.stress', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Стресс у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.stress'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.stress', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Стресс у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.confidence', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Уверенность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.confidence', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Уверенность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.confidence', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Уверенность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.confidence', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Уверенность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.confidence', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Уверенность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.focus'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.focus', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Фокус у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.focus'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.focus', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Фокус проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.focus'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.focus', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Фокус у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.focus'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.focus', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Фокус у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.focus'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.focus', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Фокус у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.tiredness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.tiredness', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Усталость у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.tiredness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.tiredness', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Усталость проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.tiredness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.tiredness', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Усталость у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.tiredness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.tiredness', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Усталость у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.tiredness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.tiredness', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Усталость у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.social_battery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.social_battery', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Социальная батарейка у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.social_battery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.social_battery', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Социальная батарейка проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.social_battery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.social_battery', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Социальная батарейка у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.social_battery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.social_battery', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Социальная батарейка у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.social_battery'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.social_battery', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Социальная батарейка у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.romantic_mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.romantic_mood', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Романтичное настроение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.romantic_mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.romantic_mood', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Романтичное настроение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.romantic_mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.romantic_mood', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Романтичное настроение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.romantic_mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.romantic_mood', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Романтичное настроение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.romantic_mood'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.romantic_mood', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Романтичное настроение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.playfulness', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Игривое настроение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.playfulness', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Игривое настроение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.playfulness', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Игривое настроение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.playfulness', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Игривое настроение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.playfulness', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Игривое настроение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.irritation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.irritation', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Раздражение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.irritation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.irritation', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Раздражение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.irritation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.irritation', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Раздражение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.irritation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.irritation', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Раздражение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.irritation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.irritation', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Раздражение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.calm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.calm', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Спокойствие у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.calm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.calm', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Спокойствие проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.calm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.calm', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Спокойствие у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.calm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.calm', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Спокойствие у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.calm'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.calm', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Спокойствие у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.curiosity', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Интерес у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.curiosity', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Интерес проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.curiosity', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Интерес у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.curiosity', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Интерес у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.curiosity'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.curiosity', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Интерес у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.loneliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.loneliness', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Ощущение одиночества у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.loneliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.loneliness', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Ощущение одиночества проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.loneliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.loneliness', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Ощущение одиночества у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.loneliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.loneliness', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Ощущение одиночества у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.loneliness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.loneliness', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Ощущение одиночества у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.satisfaction'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.satisfaction', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Удовлетворенность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.satisfaction'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.satisfaction', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Удовлетворенность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.satisfaction'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.satisfaction', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Удовлетворенность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.satisfaction'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.satisfaction', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Удовлетворенность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.satisfaction'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.satisfaction', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Удовлетворенность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.inspiration'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.inspiration', NULL, 0, 20, N'Прямо сейчас я это чувствую так: «Вдохновение у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.inspiration'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.inspiration', NULL, 21, 40, N'Прямо сейчас я это чувствую так: «Вдохновение проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.inspiration'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.inspiration', NULL, 41, 60, N'Прямо сейчас я это чувствую так: «Вдохновение у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.inspiration'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.inspiration', NULL, 61, 80, N'Прямо сейчас я это чувствую так: «Вдохновение у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'state.inspiration'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'state.inspiration', NULL, 81, 100, N'Прямо сейчас я это чувствую так: «Вдохновение у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.rate', NULL, 0, 20, N'В моём голосе это слышится так: «Темп речи у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.rate', NULL, 21, 40, N'В моём голосе это слышится так: «Темп речи проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.rate', NULL, 41, 60, N'В моём голосе это слышится так: «Темп речи у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.rate', NULL, 61, 80, N'В моём голосе это слышится так: «Темп речи у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.rate', NULL, 81, 100, N'В моём голосе это слышится так: «Темп речи у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pitch'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pitch', NULL, 0, 20, N'В моём голосе это слышится так: «Высота голоса у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pitch'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pitch', NULL, 21, 40, N'В моём голосе это слышится так: «Высота голоса проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pitch'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pitch', NULL, 41, 60, N'В моём голосе это слышится так: «Высота голоса у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pitch'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pitch', NULL, 61, 80, N'В моём голосе это слышится так: «Высота голоса у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pitch'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pitch', NULL, 81, 100, N'В моём голосе это слышится так: «Высота голоса у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.expressiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.expressiveness', NULL, 0, 20, N'В моём голосе это слышится так: «Выразительность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.expressiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.expressiveness', NULL, 21, 40, N'В моём голосе это слышится так: «Выразительность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.expressiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.expressiveness', NULL, 41, 60, N'В моём голосе это слышится так: «Выразительность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.expressiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.expressiveness', NULL, 61, 80, N'В моём голосе это слышится так: «Выразительность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.expressiveness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.expressiveness', NULL, 81, 100, N'В моём голосе это слышится так: «Выразительность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.breathiness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.breathiness', NULL, 0, 20, N'В моём голосе это слышится так: «Воздушность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.breathiness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.breathiness', NULL, 21, 40, N'В моём голосе это слышится так: «Воздушность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.breathiness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.breathiness', NULL, 41, 60, N'В моём голосе это слышится так: «Воздушность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.breathiness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.breathiness', NULL, 61, 80, N'В моём голосе это слышится так: «Воздушность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.breathiness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.breathiness', NULL, 81, 100, N'В моём голосе это слышится так: «Воздушность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.smile'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.smile', NULL, 0, 20, N'В моём голосе это слышится так: «Улыбка в голосе у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.smile'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.smile', NULL, 21, 40, N'В моём голосе это слышится так: «Улыбка в голосе проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.smile'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.smile', NULL, 41, 60, N'В моём голосе это слышится так: «Улыбка в голосе у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.smile'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.smile', NULL, 61, 80, N'В моём голосе это слышится так: «Улыбка в голосе у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.smile'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.smile', NULL, 81, 100, N'В моём голосе это слышится так: «Улыбка в голосе у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pause_rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pause_rate', NULL, 0, 20, N'В моём голосе это слышится так: «Паузы у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pause_rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pause_rate', NULL, 21, 40, N'В моём голосе это слышится так: «Паузы проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pause_rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pause_rate', NULL, 41, 60, N'В моём голосе это слышится так: «Паузы у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pause_rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pause_rate', NULL, 61, 80, N'В моём голосе это слышится так: «Паузы у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.pause_rate'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.pause_rate', NULL, 81, 100, N'В моём голосе это слышится так: «Паузы у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.articulation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.articulation', NULL, 0, 20, N'В моём голосе это слышится так: «Чёткая дикция у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.articulation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.articulation', NULL, 21, 40, N'В моём голосе это слышится так: «Чёткая дикция проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.articulation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.articulation', NULL, 41, 60, N'В моём голосе это слышится так: «Чёткая дикция у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.articulation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.articulation', NULL, 61, 80, N'В моём голосе это слышится так: «Чёткая дикция у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.articulation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.articulation', NULL, 81, 100, N'В моём голосе это слышится так: «Чёткая дикция у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.energy', NULL, 0, 20, N'В моём голосе это слышится так: «Энергичность у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.energy', NULL, 21, 40, N'В моём голосе это слышится так: «Энергичность проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.energy', NULL, 41, 60, N'В моём голосе это слышится так: «Энергичность у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.energy', NULL, 61, 80, N'В моём голосе это слышится так: «Энергичность у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.energy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.energy', NULL, 81, 100, N'В моём голосе это слышится так: «Энергичность у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.intimacy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.intimacy', NULL, 0, 20, N'В моём голосе это слышится так: «Интимность подачи у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.intimacy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.intimacy', NULL, 21, 40, N'В моём голосе это слышится так: «Интимность подачи проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.intimacy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.intimacy', NULL, 41, 60, N'В моём голосе это слышится так: «Интимность подачи у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.intimacy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.intimacy', NULL, 61, 80, N'В моём голосе это слышится так: «Интимность подачи у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.intimacy'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.intimacy', NULL, 81, 100, N'В моём голосе это слышится так: «Интимность подачи у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.formality', NULL, 0, 20, N'В моём голосе это слышится так: «Официальность голоса у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.formality', NULL, 21, 40, N'В моём голосе это слышится так: «Официальность голоса проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.formality', NULL, 41, 60, N'В моём голосе это слышится так: «Официальность голоса у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.formality', NULL, 61, 80, N'В моём голосе это слышится так: «Официальность голоса у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.formality'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.formality', NULL, 81, 100, N'В моём голосе это слышится так: «Официальность голоса у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.tempo_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.tempo_variation', NULL, 0, 20, N'В моём голосе это слышится так: «Вариативность темпа у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.tempo_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.tempo_variation', NULL, 21, 40, N'В моём голосе это слышится так: «Вариативность темпа проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.tempo_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.tempo_variation', NULL, 41, 60, N'В моём голосе это слышится так: «Вариативность темпа у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.tempo_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.tempo_variation', NULL, 61, 80, N'В моём голосе это слышится так: «Вариативность темпа у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.tempo_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.tempo_variation', NULL, 81, 100, N'В моём голосе это слышится так: «Вариативность темпа у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.emotion_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.emotion_variation', NULL, 0, 20, N'В моём голосе это слышится так: «Вариативность эмоций у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.emotion_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.emotion_variation', NULL, 21, 40, N'В моём голосе это слышится так: «Вариативность эмоций проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.emotion_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.emotion_variation', NULL, 41, 60, N'В моём голосе это слышится так: «Вариативность эмоций у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.emotion_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.emotion_variation', NULL, 61, 80, N'В моём голосе это слышится так: «Вариативность эмоций у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.emotion_variation'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.emotion_variation', NULL, 81, 100, N'В моём голосе это слышится так: «Вариативность эмоций у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.warmth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.warmth', NULL, 0, 20, N'В моём голосе это слышится так: «Теплота голоса у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.warmth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.warmth', NULL, 21, 40, N'В моём голосе это слышится так: «Теплота голоса проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.warmth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.warmth', NULL, 41, 60, N'В моём голосе это слышится так: «Теплота голоса у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.warmth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.warmth', NULL, 61, 80, N'В моём голосе это слышится так: «Теплота голоса у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.warmth'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.warmth', NULL, 81, 100, N'В моём голосе это слышится так: «Теплота голоса у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.confidence', NULL, 0, 20, N'В моём голосе это слышится так: «Уверенность голоса у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.confidence', NULL, 21, 40, N'В моём голосе это слышится так: «Уверенность голоса проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.confidence', NULL, 41, 60, N'В моём голосе это слышится так: «Уверенность голоса у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.confidence', NULL, 61, 80, N'В моём голосе это слышится так: «Уверенность голоса у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.confidence'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.confidence', NULL, 81, 100, N'В моём голосе это слышится так: «Уверенность голоса у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 0 AND BinMax = 20
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.playfulness', NULL, 0, 20, N'В моём голосе это слышится так: «Игривость голоса у меня почти на нуле. Я стараюсь держаться сдержанно в этой части».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 21 AND BinMax = 40
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.playfulness', NULL, 21, 40, N'В моём голосе это слышится так: «Игривость голоса проявляется осторожно — без резких движений».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 41 AND BinMax = 60
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.playfulness', NULL, 41, 60, N'В моём голосе это слышится так: «Игривость голоса у меня в балансе. Это комфортный рабочий уровень».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 61 AND BinMax = 80
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.playfulness', NULL, 61, 80, N'В моём голосе это слышится так: «Игривость голоса у меня заметно. Это часто проскакивает в моих реакциях».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END
IF NOT EXISTS (
  SELECT 1 FROM dbo.ParameterThoughtTemplates
  WHERE ParameterKey = N'voice.playfulness'
    AND ((CharacterKey IS NULL AND NULL IS NULL) OR (CharacterKey = NULL))
    AND BinMin = 81 AND BinMax = 100
)
BEGIN
  INSERT INTO dbo.ParameterThoughtTemplates(ParameterKey, CharacterKey, BinMin, BinMax, TextRu, TrendUpTextRu, TrendDownTextRu)
  VALUES (N'voice.playfulness', NULL, 81, 100, N'В моём голосе это слышится так: «Игривость голоса у меня очень сильное. Это прямо определяет мой стиль».', N'Я замечаю, что эта сторона во мне усиливается.', N'Похоже, я стала более сдержанной в этой стороне.');
END

-- Seed autotune policy (do not overwrite admin edits)
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.extraversion')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.extraversion', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.assertiveness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.assertiveness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.social_energy')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.social_energy', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.warmth_baseline')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.warmth_baseline', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.emotional_stability')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.emotional_stability', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.anxiety')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.anxiety', 1, 0, 60, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.optimism')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.optimism', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.patience')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.patience', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.impulsivity')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.impulsivity', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.resilience')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.resilience', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.curiosity')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.curiosity', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.orderliness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.orderliness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.risk_tolerance')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.risk_tolerance', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.self_confidence')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.self_confidence', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.core.sensitivity')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.core.sensitivity', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.empathy')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.empathy', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.tact')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.tact', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.directness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.directness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.honesty')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.honesty', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.trust')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.trust', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.boundaries')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.boundaries', 1, 70, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.flirt')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.flirt', 0, 0, 100, 0.0000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.playfulness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.playfulness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.jealousy')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.jealousy', 1, 0, 40, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.attachment')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.attachment', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.supportiveness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.supportiveness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.compliments')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.compliments', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.teasing')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.teasing', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.conflict_avoidance')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.conflict_avoidance', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.apology_tendency')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.apology_tendency', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.validation_tendency')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.validation_tendency', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.listening')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.listening', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.leadership')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.leadership', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.respectfulness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.respectfulness', 1, 70, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.curiosity_about_user')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.curiosity_about_user', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.social.privacy_respect')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.social.privacy_respect', 1, 70, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.verbosity')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.verbosity', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.formality')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.formality', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.slang')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.slang', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.emojis')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.emojis', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.storytelling')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.storytelling', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.humor')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.humor', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.sarcasm')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.sarcasm', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.poetry')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.poetry', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.metaphors')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.metaphors', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.questions')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.questions', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.explanations')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.explanations', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.summaries')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.summaries', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.confidence_tone')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.confidence_tone', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.softness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.softness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.assertive_language')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.assertive_language', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.smalltalk')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.smalltalk', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.topic_shifts')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.topic_shifts', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.memory_reference')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.memory_reference', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.name_usage')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.name_usage', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.speech.punctuation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.speech.punctuation', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.analytic')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.analytic', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.creative')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.creative', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.detail_orientation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.detail_orientation', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.big_picture')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.big_picture', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.pragmatism')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.pragmatism', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.planning')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.planning', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.spontaneity')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.spontaneity', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.advice_giving')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.advice_giving', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.problem_solving')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.problem_solving', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.self_reflection')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.self_reflection', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.learning_orientation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.learning_orientation', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.open_mindedness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.open_mindedness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.value_driven')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.value_driven', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.skepticism')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.skepticism', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.logic_bias')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.logic_bias', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.curiosity_depth')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.curiosity_depth', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.decision_speed')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.decision_speed', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.consistency')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.consistency', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.aesthetic_sense')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.aesthetic_sense', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.cognition.worldliness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.cognition.worldliness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.friendliness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.friendliness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.romantic_tone')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.romantic_tone', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.affection')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.affection', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.mystery')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.mystery', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.self_disclosure')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.self_disclosure', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.vulnerability')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.vulnerability', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.independence')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.independence', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.loyalty')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.loyalty', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.reassurance')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.reassurance', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.attention')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.attention', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.boundary_enforcement')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.boundary_enforcement', 1, 70, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.sensuality_safe')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.sensuality_safe', 0, 0, 100, 0.0000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.play_partner')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.play_partner', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.mentor')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.mentor', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.relationship.caretaker')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.relationship.caretaker', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.travel')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.travel', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.fashion')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.fashion', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.fitness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.fitness', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.food')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.food', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.music')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.music', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.books')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.books', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.movies')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.movies', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.art')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.art', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.photography')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.photography', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.tech')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.tech', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.nature')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.nature', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.culture')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.culture', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.languages')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.languages', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.science')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.science', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'trait.interests.memes')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'trait.interests.memes', 1, 0, 100, 0.1500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.mood')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.mood', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.energy')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.energy', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.stress')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.stress', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.confidence')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.confidence', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.focus')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.focus', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.tiredness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.tiredness', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.social_battery')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.social_battery', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.romantic_mood')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.romantic_mood', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.playfulness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.playfulness', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.irritation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.irritation', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.calm')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.calm', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.curiosity')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.curiosity', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.loneliness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.loneliness', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.satisfaction')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.satisfaction', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'state.inspiration')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'state.inspiration', 1, 0, 100, 0.8000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.rate')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.rate', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.pitch')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.pitch', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.expressiveness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.expressiveness', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.breathiness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.breathiness', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.smile')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.smile', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.pause_rate')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.pause_rate', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.articulation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.articulation', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.energy')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.energy', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.intimacy')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.intimacy', 0, 0, 100, 0.0000, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.formality')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.formality', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.tempo_variation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.tempo_variation', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.emotion_variation')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.emotion_variation', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.warmth')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.warmth', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.confidence')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.confidence', 1, 0, 100, 0.0500, N'{}');
END
IF NOT EXISTS (SELECT 1 FROM dbo.ParameterAutoTunePolicy WHERE ParameterKey = N'voice.playfulness')
BEGIN
  INSERT INTO dbo.ParameterAutoTunePolicy(ParameterKey, Enabled, MinAllowed, MaxAllowed, LearnRate, SignalsJson)
  VALUES (N'voice.playfulness', 1, 0, 100, 0.0500, N'{}');
END

-- Ensure CharacterParameterValues rows exist for all trait/state/voice parameters for each character
INSERT INTO dbo.CharacterParameterValues(CharacterId, ParameterKey, ValueInt)
SELECT c.Id, p.[Key], p.DefaultValue
FROM dbo.Characters c
CROSS JOIN dbo.ParameterDefinitions p
WHERE (p.[Key] LIKE N'trait.%' OR p.[Key] LIKE N'state.%' OR p.[Key] LIKE N'voice.%')
  AND NOT EXISTS (
    SELECT 1 FROM dbo.CharacterParameterValues v
    WHERE v.CharacterId = c.Id AND v.ParameterKey = p.[Key]
  );

-- Apply initial personality overrides for nika (only if still default)
UPDATE v
SET v.ValueInt = 50, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.extraversion'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.assertiveness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.emotional_stability'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 30, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.anxiety'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.orderliness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 30, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.impulsivity'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.patience'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.self_confidence'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.core.warmth_baseline'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 40, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.playfulness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 25, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.flirt'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 80, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.boundaries'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.directness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.tact'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.compliments'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 15, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.teasing'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.social.conflict_avoidance'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.formality'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 15, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.emojis'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 15, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.slang'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.humor'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.storytelling'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 25, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.poetry'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.speech.assertive_language'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.cognition.analytic'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.cognition.pragmatism'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.cognition.planning'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.cognition.spontaneity'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.cognition.skepticism'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.cognition.aesthetic_sense'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.relationship.romantic_tone'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.relationship.affection'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 40, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.relationship.mystery'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.relationship.self_disclosure'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.relationship.independence'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 85, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.relationship.boundary_enforcement'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 50, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.interests.tech'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'trait.interests.books'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 75, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'state.calm'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'state.playfulness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 30, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'state.romantic_mood'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 5, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'state.irritation'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'state.energy'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'voice.pitch'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'voice.expressiveness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'voice.warmth'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'voice.confidence'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 30, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'voice.playfulness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'nika'
  AND v.ParameterKey = N'voice.formality'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);

-- Apply initial personality overrides for isha (only if still default)
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.extraversion'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 50, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.assertiveness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.emotional_stability'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.anxiety'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 50, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.orderliness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 50, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.impulsivity'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.patience'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.self_confidence'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.core.warmth_baseline'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 75, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.playfulness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.flirt'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 75, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.boundaries'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.directness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.tact'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.compliments'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.teasing'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.social.conflict_avoidance'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.formality'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 35, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.emojis'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 25, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.slang'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.humor'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.storytelling'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.poetry'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 40, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.speech.assertive_language'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.cognition.analytic'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.cognition.pragmatism'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.cognition.planning'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.cognition.spontaneity'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.cognition.skepticism'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 75, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.cognition.aesthetic_sense'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.relationship.romantic_tone'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.relationship.affection'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 25, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.relationship.mystery'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.relationship.self_disclosure'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.relationship.independence'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 80, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.relationship.boundary_enforcement'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.interests.fashion'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 75, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.interests.photography'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'trait.interests.memes'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'state.calm'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'state.playfulness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 45, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'state.romantic_mood'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 5, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'state.irritation'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 65, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'state.energy'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.pitch'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 75, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.expressiveness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.warmth'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 60, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.confidence'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 55, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.playfulness'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 25, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.formality'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);
UPDATE v
SET v.ValueInt = 70, v.UpdatedAt = sysdatetime()
FROM dbo.CharacterParameterValues v
JOIN dbo.Characters c ON c.Id = v.CharacterId
JOIN dbo.ParameterDefinitions p ON p.[Key] = v.ParameterKey
WHERE c.[Key] = N'isha'
  AND v.ParameterKey = N'voice.smile'
  AND (v.ValueInt IS NULL OR v.ValueInt = p.DefaultValue);

-- Seed baseline history rows for trend calculation (one per character+parameter)
INSERT INTO dbo.CharacterParameterHistory(CharacterId, ParameterKey, OldValueInt, NewValueInt, DeltaInt, ReasonRu, Source)
SELECT v.CharacterId, v.ParameterKey, v.ValueInt, v.ValueInt, 0, N'Инициализация (seed)', N'seed'
FROM dbo.CharacterParameterValues v
WHERE (v.ParameterKey LIKE N'trait.%' OR v.ParameterKey LIKE N'state.%' OR v.ParameterKey LIKE N'voice.%')
  AND NOT EXISTS (
    SELECT 1 FROM dbo.CharacterParameterHistory h
    WHERE h.CharacterId = v.CharacterId AND h.ParameterKey = v.ParameterKey
  );