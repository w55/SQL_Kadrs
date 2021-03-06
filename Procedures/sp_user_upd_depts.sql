USE [Kadrs]
GO
/****** Object:  StoredProcedure [dbo].[sp_user_upd_depts]    Script Date: 27.02.2017 8:47:13 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

--
--		изменяем данные текущего сотрудника базы данных "Кадры"
--		изменяем отдел на новый в приходах - если стоит флаг @is_change
--
ALTER                   PROCEDURE [dbo].[sp_user_upd_depts]
	@dbuser_id int, @upd_whom int, @last_name varchar(100), @first_name varchar(100), @mid_name varchar(100),
	@birth_date varchar(20),
	@hash_1 int, @hash_2 int, @dep_id int, @is_reception bit, @is_hidden bit, @is_change bit = 0,
	@chng_date varchar(20) = NULL, @user_desc varchar(250) = NULL
as

IF EXISTS(SELECT * FROM db_users  WHERE (upper(ltrim(last_name)) = upper(ltrim(@last_name)) and 
	upper(ltrim(first_name)) = upper(ltrim(@first_name)) and 
	upper(left(mid_name,1)) = upper(left(@mid_name,1)) and
	dbuser_id != @dbuser_id))
begin
	RAISERROR(' Ошибка изменения записи: Пользователь: %s %s  %s-  в таблице db_users уже существует !!!',
		16, 1, @last_name, @first_name, @mid_name)
	return - 1
end

IF @dbuser_id <= 2
begin
	RAISERROR(' Ошибка изменения записи № %d из таблицы db_users: Номер записи должен быть больше 2',
		16, 1, @dbuser_id)
	return - 1
end

--
IF NOT EXISTS(select * from departments where dep_id = @dep_id)
begin
	RAISERROR(' Ошибка : В таблице ОТДЕЛЫ - не существует указанного отдела !!! ', 16, 1)
	return -1
end

--
--
IF @is_change = 1 and @chng_date is null
begin
	RAISERROR(' Ошибочные входные параметры: не задана начальная дата для изменения прихода на работу !!!', 16, 1)
	return -1
end

--	преобразуем дату
declare @dt1 as datetime, @dt2 as datetime, @c_dt2 varchar(20)
declare @y1 as int, @m1 as int, @d1 as int

set @dt1 = convert(datetime,@chng_date,104)

--
set @y1 = year(@dt1)
set @m1 = month(@dt1)
set @d1 = day(@dt1)

--	преобразуем дату
set @c_dt2 = ltrim(rtrim(str(@d1))) + '.' + ltrim(rtrim(str(@m1))) + '.' + ltrim(rtrim(str(@y1))) + ' 0:00:00'
set @dt2 = convert(datetime,@c_dt2,104)



if @hash_1 is null or @hash_2 is null
begin
	update db_users
		set dep_id = @dep_id, last_name = @last_name, first_name = @first_name, mid_name = @mid_name,
		birth_date = convert(datetime,@birth_date,104),
		is_reception = @is_reception, is_hidden = @is_hidden, user_desc = @user_desc,
		upd_whom = @upd_whom, upd_when = getdate()
			where dbuser_id = @dbuser_id
end
else
begin
	update db_users
		set dep_id = @dep_id, last_name = @last_name, first_name = @first_name, mid_name = @mid_name,
		birth_date = convert(datetime,@birth_date,104),
		hash_1 = @hash_1, hash_2 = @hash_2,
		is_reception = @is_reception, is_hidden = @is_hidden, user_desc = @user_desc,
		upd_whom = @upd_whom, upd_when = getdate()
			where dbuser_id = @dbuser_id
end
IF @@ROWCOUNT = 0
begin
	RAISERROR(' Ошибка изменения записи в таблице db_users: Запись № %d - не найдена !!!',16, 1, @dbuser_id)
	return -1
end


--
--	обновляем информацию в таблице income (меняем отдел на новый)
--

update income
	set dep_id = @dep_id
	where dbuser_id = @dbuser_id and come_time >= @dt2



