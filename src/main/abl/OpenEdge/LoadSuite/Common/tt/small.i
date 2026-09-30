
/*------------------------------------------------------------------------
    File        : small.i
    Purpose     : Small temp table definition
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/
DEFINE TEMP-TABLE SmallTable NO-UNDO
    FIELD PUK           AS INT64 
    FIELD charField     AS CHARACTER 
    FIELD dateField     AS DATE 
    FIELD dateTimeField AS DATETIME   
    FIELD dateTZField   AS DATETIME-TZ 
    FIELD intField      AS INTEGER 
    FIELD in64Field     AS INT64 
    FIELD decField      AS DECIMAL
    INDEX PriIdx IS PRIMARY 
        PUK ASCENDING.   