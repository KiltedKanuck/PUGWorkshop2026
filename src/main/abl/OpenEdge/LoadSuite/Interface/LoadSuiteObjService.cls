/**************************************************************************************************************************
Copyright (c) 2026 by Progress Software Corporation and/or one of its subsidiaries or affiliates. All rights reserved.
***************************************************************************************************************************/
/*------------------------------------------------------------------------
    File        : SampleService
    Purpose     : Demonstrate a simple service interface for code samples
    Description :
    Author(s)   : Dustin Grau
    Created     : Thu Mar 26 10:51:14 EDT 2026
    Notes       :

    DOH Mapping: objects.map

    This is the service interface for the LoadSuite application. This has a
    direct correlation to the DOH mapping defined in loadsuite.map

    When you add/modify this file make sure to update the corresponding DOH
    mapping in objects.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

class OpenEdge.LoadSuite.Interface.LoadSuiteObjService
    use-widget-pool
    final
:
    // Access the service-level logging manager.
    define protected property oLogger as ILogWriter no-undo
        get():
            // Create single logger instance for this class.
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.

    // Create a single instance of the general math float class.
    define protected property oMathFloat as OpenEdge.LoadSuite.Objects.math.float.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oMathFloat) then
                assign oMathFloat = new OpenEdge.LoadSuite.Objects.math.float.general().
            return oMathFloat.
        end get.
        private set.

    // Create a single instance of the general math integer class.
    define protected property oMathInteger as OpenEdge.LoadSuite.Objects.math.integer.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oMathInteger) then
                assign oMathInteger = new OpenEdge.LoadSuite.Objects.math.integer.general().
            return oMathInteger.
        end get.
        private set.

    // Create a single instance of the general math long class.
    define protected property oMathLong as OpenEdge.LoadSuite.Objects.math.long.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oMathLong) then
                assign oMathLong = new OpenEdge.LoadSuite.Objects.math.long.general().
            return oMathLong.
        end get.
        private set.

    // Create a single instance of the general string long class.
    define protected property oStringLong as OpenEdge.LoadSuite.Objects.string.long.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oStringLong) then
                assign oStringLong = new OpenEdge.LoadSuite.Objects.string.long.general().
            return oStringLong.
        end get.
        private set.

    // Create a single instance of the general string short class.
    define protected property oStringShort as OpenEdge.LoadSuite.Objects.string.short.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oStringShort) then
                assign oStringShort = new OpenEdge.LoadSuite.Objects.string.short.general().
            return oStringShort.
        end get.
        private set.

    // Create a single instance of the general temp-table class.
    define protected property oTempTable as OpenEdge.LoadSuite.Objects.temptable.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oTempTable) then
                assign oTempTable = new OpenEdge.LoadSuite.Objects.temptable.general().
            return oTempTable.
        end get.
        private set.

    constructor LoadSuiteObjService ( ):
        // Constructor can be used to initialize any instance-level data or resources.
    end constructor.

    method public void floatAddition ( input  iNum1 as decimal,
                                       input  iNum2 as decimal,
                                       output oResult as decimal ):
        assign oResult = oMathFloat:addition(iNum1, iNum2).
    end method. // floatAddition

    method public void floatSubtraction ( input  iNum1 as decimal,
                                          input  iNum2 as decimal,
                                          output oResult as decimal ):
        assign oResult = oMathFloat:subtraction(iNum1, iNum2).
    end method. // floatSubtraction

    method public void floatMultiplication ( input  iNum1 as decimal,
                                             input  iNum2 as decimal,
                                             output oResult as decimal ):
        assign oResult = oMathFloat:multiplication(iNum1, iNum2).
    end method. // floatMultiplication

    method public void floatDivision ( input  iNum1 as decimal,
                                       input  iNum2 as decimal,
                                       output oResult as decimal ):
        assign oResult = oMathFloat:division(iNum1, iNum2).
    end method. // floatDivision

    method public void integerAddition ( input  iNum1 as integer,
                                         input  iNum2 as integer,
                                         output oResult as integer ):
        assign oResult = oMathInteger:addition(iNum1, iNum2).
    end method. // integerAddition

    method public void integerSubtraction ( input  iNum1 as integer,
                                            input  iNum2 as integer,
                                            output oResult as integer ):
        assign oResult = oMathInteger:subtraction(iNum1, iNum2).
    end method. // integerSubtraction

    method public void integerMultiplication ( input  iNum1 as integer,
                                               input  iNum2 as integer,
                                               output oResult as integer ):
        assign oResult = oMathInteger:multiplication(iNum1, iNum2).
    end method. // integerMultiplication

    method public void integerDivision ( input  iNum1 as integer,
                                         input  iNum2 as integer,
                                         output oResult as integer ):
        assign oResult = oMathInteger:division(iNum1, iNum2).
    end method. // integerDivision

    method public void longAddition ( input  iNum1 as int64,
                                      input  iNum2 as int64,
                                      output oResult as int64 ):
        assign oResult = oMathLong:addition(iNum1, iNum2).
    end method. // longAddition

    method public void longSubtraction ( input  iNum1 as int64,
                                         input  iNum2 as int64,
                                         output oResult as int64 ):
        assign oResult = oMathLong:subtraction(iNum1, iNum2).
    end method. // longSubtraction

    method public void longMultiplication ( input  iNum1 as int64,
                                            input  iNum2 as int64,
                                            output oResult as int64 ):
        assign oResult = oMathLong:multiplication(iNum1, iNum2).
    end method. // longMultiplication

    method public void longDivision ( input  iNum1 as int64,
                                      input  iNum2 as int64,
                                      output oResult as int64 ):
        assign oResult = oMathLong:division(iNum1, iNum2).
    end method. // longDivision

    method public void stringLongWhatLetter ( input  iLoc as integer,
                                              output oResult as character ):
        assign oResult = oStringLong:WhatLetter(iLoc).
    end method. // stringLongWhatLetter

    method public void stringLongWhatWord ( input  iStart as integer,
                                            input  iLength as integer,
                                            output oResult as character ):
        assign oResult = oStringLong:WhatWord(iStart, iLength).
    end method. // stringLongWhatWord

    method public void stringShortFindIn ( input  iLetter as character,
                                           output oResult as integer ):
        assign oResult = oStringShort:FindIn(iLetter).
    end method. // stringShortFindIn

    method public void stringShortHelloJoin ( input  iWord as character,
                                              output oResult as character ):
        assign oResult = oStringShort:HelloJoin(iWord).
    end method. // stringShortHelloJoin

    method public void stringShortWhatLetter ( input  iNum as integer,
                                               output oResult as character ):
        assign oResult = oStringShort:WhatLetter(iNum).
    end method. // stringShortWhatLetter

    method public void stringShortWhatWord ( input  iStart as integer,
                                             input  iLength as integer,
                                             output oResult as character ):
        assign oResult = oStringShort:WhatWord(iStart, iLength).
    end method. // stringShortWhatWord

    method public void tempTableCreateDynamic ( input  iNumFields as integer,
                                                output oResult as logical ):
        assign oResult = oTempTable:CreateDynamic(iNumFields).
    end method. // tempTableCreateDynamic

    method public void tempTableCreateStatic ( input  kTableName as character,
                                               output oResult as logical ):
        assign oResult = oTempTable:CreateStatic(kTableName).
    end method. // tempTableCreateStatic

    method public void tempTableAddRecords ( input  iNumToCreate as int64,
                                             output oResult as int64 ):
        assign oResult = oTempTable:AddRecords(iNumToCreate).
    end method. // tempTableAddRecords

    method public void tempTableDeleteTable ( output oResult as logical ):
        assign oResult = oTempTable:DeleteTable().
    end method. // tempTableDeleteTable

end class.