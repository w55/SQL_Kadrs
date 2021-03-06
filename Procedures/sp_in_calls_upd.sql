USE [Kadrs]
GO
/****** Object:  StoredProcedure [dbo].[sp_in_calls_upd]    Script Date: 27.02.2017 8:50:36 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

--		офис-менеджер редактирует текущий входящий звонок 
--		возвращаемое значение: номер и дата текущего звонка
--
ALTER               PROCEDURE [dbo].[sp_in_calls_upd]
	@call_id int, @upd_whom int, @ini_time varchar(20), @client_type_id int, @dep_id int, @source_id int,
	@call_desc varchar(250), @call_nmbc varchar(30) = NULL output
AS

IF @upd_whom < 1
begin
	RAISERROR(' Ошибочные входные параметры : Номер пользователя (%d) - должен быть больше нуля !!!', 16, 1, @upd_whom)
	return -1
end

IF @dep_id < 1
begin
	RAISERROR(' Ошибочные входные параметры : Номер отдела (%d) - должен быть больше нуля !!!', 16, 1, @dep_id)
	return -1
end

IF @source_id < 1
begin
	RAISERROR(' Ошибочные входные параметры : Номер источника информации (%d) - должен быть больше нуля !!!',
		16, 1, @source_id)
	return -1
end

IF @client_type_id < 1
begin
	RAISERROR(' Ошибочные входные параметры : Тип клиента (%d) - должен быть больше нуля !!!', 16, 1, @client_type_id)
	return -1
end

IF @ini_time is null
begin
	RAISERROR(' Ошибочные входные параметры: не заданы дата и время начала звонка ', 16, 1)
	return -1
end

--	преобразуем дату
declare @dt1 as datetime
set @dt1 = convert(datetime,@ini_time,104)


IF NOT EXISTS(SELECT * FROM in_calls  WHERE call_id = @call_id)
begin
	RAISERROR(' Ошибочные входные параметры:  Записи с внутр. номером: %d -  в таблице ВХОДЯЩИЕ ЗВОНКИ - не существует !!!',
		16, 1, @call_id)
	return - 1
end

--
--	изменяем текущую запись в таблице in_calls:
--
update in_calls
	set ini_time = @dt1, client_type_id = @client_type_id, dep_id = @dep_id, source_id = @source_id,
		call_desc = ltrim(rtrim(@call_desc)), upd_whom = @upd_whom, upd_when = getdate()
		where call_id = @call_id


IF @@ROWCOUNT = 0
begin
	RAISERROR(' Ошибка изменения записи в таблице ВХОДЯЩИЕ ЗВОНКИ: Запись № %d - не найдена !!!',16, 1, @call_id)
	return -1
end

--	возвращаемое значение: номер и дата текущего звонка
--
set @call_nmbc = ltrim(rtrim(@call_id)) + '  от  ' + ltrim(rtrim(convert(varchar(20),@dt1,104)))



