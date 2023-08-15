-- таблица метаданных с дублями актуальных версий
SELECT
	md._MetadataId,
	MAX(md._MetadataVersionNumber) as MetadataMaxVersion
into ##meta_doubles_error
FROM [dbo].[_DataHistoryMetadata] as md
where md._IsActual = 0x01
group by md._MetadataId
having count(md._MetadataVersionNumber) > 1

-- Устанавливаем актуальной последнюю версию метаданных
Update md set _IsActual = 0x01
FROM [dbo].[_DataHistoryMetadata] as md
	inner join ##meta_doubles_error as e
		on md._MetadataId = e._MetadataId
where 
	md._MetadataVersionNumber = e.MetadataMaxVersion
	and md._IsActual = 0x00

-- Устанавливаем НЕ актуальной все предыдущие версии метаданных
Update md set _IsActual = 0x00
FROM [dbo].[_DataHistoryMetadata] as md
	inner join ##meta_doubles_error as e
		on md._MetadataId = e._MetadataId
where 
	md._MetadataVersionNumber < e.MetadataMaxVersion
	and md._IsActual = 0x01

-- изменяем версию метаданных для всех версий объектов
-- иначе все версии будут привязаны к старой (зависшей) метаверсии
Update v set v._MetadataVersionNumber = e.MetadataMaxVersion
	FROM [dbo].[_DataHistoryMetadata] as md
		inner join ##meta_doubles_error as e
			on md._MetadataId = e._MetadataId
		inner join [dbo].[_DataHistoryLatestVersions1] as l
			on md._MetadataId = l._MetadataId 
		left join [dbo].[_DataHistoryVersions] as v
			on v._HistoryDataId = l._HistoryDataId
				and v._MetadataVersionNumber = md._MetadataVersionNumber
	Where v._MetadataVersionNumber != e.MetadataMaxVersion

drop table ##meta_doubles_error