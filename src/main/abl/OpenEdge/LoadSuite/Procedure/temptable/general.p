
/*------------------------------------------------------------------------
    File        : general.p
    Purpose     : Test language temp-table creation both static and
                  dynamic from within a procedure

    Author(s)   : Cameron David Wright
    Created     : Thu Oct 13 18:20:44 UTC 2022
    Notes       :
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

    { OpenEdge/LoadSuite/Common/tt/small.i }
    { OpenEdge/LoadSuite/Common/tt/large.i }

/* ***************************  Main Block  *************************** */
    define variable hTT         as handle no-undo.
    define variable hBuffer     as handle no-undo.
    define variable hQuery      as handle no-undo. 
    
        
    assign
        hTT = ?
        hBuffer = ?
        hQuery = ?.

    /**
     * Adds records to the temp-table.
     *
     * @param iNumToCreate Number of records to create.
     * @return The number of records created.
     */
    function AddRecords returns int64( input iNumToCreate as int64 ):
        
        define variable result      as int64 no-undo.
        define variable iCount      as int64 no-undo.
        define variable hField      as handle no-undo.
        define variable iCreated    as int64 init 0 no-undo.
        
        do iCount = 1 to iNumToCreate:
            hBuffer:buffer-create ().
            assign 
            hBuffer:buffer-field("PUK"):buffer-value() = iCount
            iCreated = iCreated + 1.
        end.
        RESULT = iCreated.
        
        return result.

    end function.

    /**
     * Creates a dynamic temp-table with the specified number of fields.
     *
     * @param iNumFields Number of fields to create in the temp-table.
     * @return True if the temp-table was successfully created.
     */
    function CreateDynamic returns logical( input iNumFields as integer  ):
        define variable result as logical init false no-undo. 
        
        define variable kTableName  as character no-undo.
        define variable iCount      as integer no-undo.
        define variable iDataType   as integer no-undo.
        define variable kDataType   as character 
                    init "char,int,date,dec,datetime,datetime-tz,int64" no-undo.
        
        assign
            kTableName = "Dynamic" + STRING(iNumFields)
            iDataType  = random(1,7).
        
        
        create temp-table hTT.
        hTT:add-new-field("PUK","int64").
        do iCount = 1 to iNumFields:
            hTT:add-new-field(string ("Field" + ENTRY(iDataType, kDataType ) + STRING(iNumFields)), 
                              entry(iDataType, kDataType) ).        
        end.
        
        hTT:temp-table-prepare(kTableName).
        /* add buffer */
        hBuffer = hTT:default-buffer-handle.
        
        if valid-handle(htt) 
            and VALID-HANDLE(hBuffer) then assign RESULT = true. 
    
        return result. 
         
    end.

    /**
     * Creates a static temp-table based on an existing table definition.
     *
     * @param kTableName Name of the table to copy (SmallTable or LargeTable).
     * @return True if the temp-table was successfully created.
     */
    function CreateStatic returns logical( input kTableName as character  ):
        
        define variable result as logical init false no-undo.

        if kTableName ne "SmallTable" and kTableName ne "LargeTable" then return RESULT.

        create temp-table hTT.
        hTT:create-like(kTableName).
        hTT:temp-table-prepare(kTableName + "Copy").
        /* add buffer */
        hBuffer = hTT:default-buffer-handle.
        
        if valid-handle(htt) 
            and VALID-HANDLE(hBuffer) then assign RESULT = true. 
    
        return result.

    end .

    /**
     * Deletes the temp-table and cleans up resources.
     *
     * @return True if the temp-table was successfully deleted.
     */
    function DeleteTable returns logical (  ):
        
        define variable result as logical init false no-undo.

        hTT:empty-temp-table(). 

        if valid-handle(hQuery) then delete object hQuery no-error .
        if valid-handle(hTT) then delete object hTT no-error .
        
        if (not valid-handle(hQuery) and 
            not VALID-HANDLE(hTT)) then 
            RESULT = true.
        
        return result.

    end .        
