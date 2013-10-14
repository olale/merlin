DECLARE @name sysname, @object_id sysname, @new_name sysname
DECLARE fk_cursor CURSOR FOR 
SELECT name, object_id
FROM sys.foreign_keys
OPEN fk_cursor
    FETCH NEXT FROM fk_cursor INTO @name, @object_id
    SET @new_name = 'FK_' + convert(varchar(max),@object_id)
    WHILE @@FETCH_STATUS = 0
    BEGIN
       EXEC sp_rename @name, @new_name
       FETCH NEXT FROM fk_cursor INTO @name, @object_id
    END
    EXEC sp_rename @name, @new_name
CLOSE fk_cursor
DEALLOCATE fk_cursor
