
/*------------------------------------------------------------------------
    File        : large.i
    Purpose     : Large temp table definition
    Author(s)   : Cameron David Wright
    Notes       :
  ----------------------------------------------------------------------*/

define {1} temp-table LargeTable no-undo
        before-table before_LargeTable
    field PUK               as int64 
    field charField1        as character 
    field charField2        as character
    field charField3        as character
    field charField4        as character
    field charField5        as character
    field charField6        as character
    field charField7        as character
    field charField8        as character
    field charField9        as character
    field charField0        as character
    field dateField0        as date 
    field dateField1        as date
    field dateField2        as date
    field dateField3        as date
    field dateField4        as date
    field dateField5        as date
    field dateField6        as date
    field dateField7        as date
    field dateField8        as date
    field dateField9        as date
    field dateTimeField0    as datetime   
    field dateTimeField1    as datetime
    field dateTimeField2    as datetime
    field dateTimeField3    as datetime
    field dateTimeField4    as datetime
    field dateTimeField5    as datetime
    field dateTimeField6    as datetime
    field dateTimeField7    as datetime
    field dateTimeField8    as datetime
    field dateTimeField9    as datetime
    field dateTZField0      as datetime-tz 
    field dateTZField1      as datetime-tz
    field dateTZField2      as datetime-tz
    field dateTZField3      as datetime-tz
    field dateTZField4      as datetime-tz
    field dateTZField5      as datetime-tz
    field dateTZField6      as datetime-tz
    field dateTZField7      as datetime-tz
    field dateTZField8      as datetime-tz
    field dateTZField9      as datetime-tz
    field intField0         as integer 
    field intField1         as integer
    field intField2         as integer
    field intField3         as integer
    field intField4         as integer
    field intField5         as integer
    field intField6         as integer
    field intField7         as integer
    field intField8         as integer
    field intField9         as integer
    field in64Field0        as int64 
    field in64Field1        as int64
    field in64Field2        as int64
    field in64Field3        as int64
    field in64Field4        as int64
    field in64Field5        as int64
    field in64Field6        as int64
    field in64Field7        as int64
    field in64Field8        as int64
    field in64Field9        as int64
    field decField0         as decimal
    field decField1         as decimal
    field decField2         as decimal
    field decField3         as decimal
    field decField4         as decimal
    field decField5         as decimal
    field decField6         as decimal
    field decField7         as decimal
    field decField8         as decimal
    field decField9
             as decimal
    index PriIdx is primary 
        PUK ascending.   