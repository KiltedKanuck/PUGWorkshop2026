 /*------------------------------------------------------------------------
    File        : OpenEdge.LoadSuite.Objects.temptable.general
    Purpose     : Dynamic and static temp-table management utilities
    Description : Provides methods for creating, populating, and managing temp-tables
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

/**
 * Temp-table management utilities.
 *
 * Provides functionality for creating and managing both dynamic and static temp-tables,
 * including record creation, table deletion, and handle-based operations.
 *
 * @author Cameron David Wright <openedge>
 * @since 1.0
 * @version 1.0
 */
class OpenEdge.LoadSuite.Objects.temptable.general serializable : 

    { OpenEdge/LoadSuite/Common/tt/small.i }
    { OpenEdge/LoadSuite/Common/tt/large.i SERIALIZABLE } 

    /**
     * Handle to the temp-table.
     */
    define private variable hTT         as handle no-undo.
    
    /**
     * Handle to the temp-table buffer.
     */
    define private variable hBuffer     as handle no-undo.
    
    /**
     * Handle to the query object.
     */
    define private variable hQuery      as handle no-undo.
        
    /**
     * Initializes a new instance of `OpenEdge.LoadSuite.Objects.temptable.general`.
     *
     * Initializes all handle variables to unknown value.
     */
    constructor public general (  ):
        super ().
        assign
            hTT = ?
            hBuffer = ?
            hQuery = ?.
        
    end constructor.


    /**
     * Adds records to the temp-table buffer.
     *
     * Creates the specified number of records in the temp-table buffer,
     * setting the PUK field to sequential values.
     *
     * @param iNumToCreate The number of records to create.
     * @return The number of records successfully created.
     */
    method public int64 AddRecords( input iNumToCreate as int64 ):
        
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

    end method.

    /**
     * Creates a dynamic temp-table with the specified number of fields.
     *
     * Dynamically creates a temp-table with a PUK field and the specified number
     * of additional fields. Field data types are randomly selected from available types.
     *
     * @param iNumFields The number of fields to add to the temp-table.
     * @return True if the temp-table and buffer were successfully created, false otherwise.
     */
    method public logical CreateDynamic( input iNumFields as integer  ):
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
        hBuffer = hTT:default-buffer-handle.
        
        if valid-handle(htt) 
            and VALID-HANDLE(hBuffer) then assign RESULT = true. 
    
        return result. 
         
    end.

    /**
     * Creates a static temp-table based on an existing table definition.
     *
     * Creates a temp-table with the same structure as the specified table.
     * Only supports "SmallTable" and "LargeTable" as source tables.
     *
     * @param kTableName The name of the table to copy ("SmallTable" or "LargeTable").
     * @return True if the temp-table and buffer were successfully created, false otherwise.
     */
    method public logical CreateStatic( input kTableName as character  ):
        
        define variable result as logical init false no-undo.

        if kTableName ne "SmallTable" and kTableName ne "LargeTable" then return RESULT.

        create temp-table hTT.
        hTT:create-like(kTableName).
        hTT:temp-table-prepare(kTableName + "Copy").
        hBuffer = hTT:default-buffer-handle.
        
        if valid-handle(htt) 
            and VALID-HANDLE(hBuffer) then assign RESULT = true. 
    
        return result.

    end method.

    /**
     * Deletes the temp-table and associated objects.
     *
     * Empties the temp-table and deletes the query and table handles.
     *
     * @return True if all handles were successfully deleted, false otherwise.
     */
    method public logical DeleteTable(  ):
        
        define variable result as logical init false no-undo.

        hTT:empty-temp-table(). 

        if valid-handle(hQuery) then delete object hQuery no-error .
        if valid-handle(hTT) then delete object hTT no-error .
        
        if (not valid-handle(hQuery) and 
            not VALID-HANDLE(hTT)) then 
            RESULT = true.
        
        return result.

    end method.

    /**
     * Releases resources held by this instance.
     *
     * Deletes all handle objects and resets handle variables to unknown value.
     */
    destructor public general ( ):
        delete object hTT no-error .
        delete object hBuffer no-error .
        delete object hQuery no-error .
        assign
            hTT = ?
            hBuffer = ?
            hQuery = ?.
        
    end destructor.

end class.