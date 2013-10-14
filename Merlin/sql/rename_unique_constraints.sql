DECLARE @old sysname, @current sysname, @TABLE sysname, @COLUMN sysname,
    @this_old sysname
DECLARE uq_cursor CURSOR FOR 
    SELECT AllUQs.name AS old_name, object_name(AllUQs.parent_obj) AS table_name,
            col.name AS column_name
        FROM dbo.sysobjects AS AllUQs
        JOIN dbo.sysindexes AS ix ON (ix.id = AllUQs.parent_obj)
                               AND (ix.name = AllUQs.name)
        JOIN dbo.sysindexkeys AS [KEY] ON ([KEY].id = ix.id) AND ([KEY].indid = ix.indid)
        JOIN dbo.syscolumns AS col ON (col.id = ix.id) AND (col.colid = [KEY].colid)
        WHERE AllUQs.xtype = 'UQ'
        ORDER BY old_name
OPEN uq_cursor
    FETCH NEXT FROM uq_cursor INTO @old, @TABLE, @COLUMN
    SET @current = 'UQ_' + @TABLE
    SET @this_old = @old
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (@this_old != @old)
        BEGIN
            -- print @this_old + ' - ' + @current
            EXEC sp_rename @this_old, @current, 'OBJECT'
            SET @current = 'UQ_' + @TABLE + '_' + @COLUMN
            SET @this_old = @old
        END
        ELSE
        BEGIN
            SET @current = @current + '__' + @COLUMN
        END
        FETCH NEXT FROM uq_cursor INTO @old, @TABLE, @COLUMN
    END
    -- print @this_old + ' - ' + @current
    EXEC sp_rename @this_old, @current, 'OBJECT'
CLOSE uq_cursor
DEALLOCATE uq_cursor
