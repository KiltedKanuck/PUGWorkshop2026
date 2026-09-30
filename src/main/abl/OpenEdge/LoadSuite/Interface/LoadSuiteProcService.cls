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

    DOH Mapping: procedures.map

    This is the service interface for the LoadSuite application. This has a
    direct correlation to the DOH mapping defined in loadsuite.map

    When you add/modify this file make sure to update the corresponding DOH
    mapping in procedures.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

class OpenEdge.LoadSuite.Interface.LoadSuiteProcService
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

    // Create a single instance of the general math float procedure.
    define protected property hMathFloat as handle no-undo
        get():
            // Create single instance for this procedure.
            if not valid-handle(hMathFloat) then
                run "OpenEdge/LoadSuite/Procedure/math/float/general.p" persistent set hMathFloat.
            return hMathFloat.
        end get.
        private set.

    // Create a single instance of the general math integer procedure.
    define protected property hMathInteger as handle no-undo
        get():
            // Create single instance for this procedure.
            if not valid-handle(hMathInteger) then
                run "OpenEdge/LoadSuite/Procedure/math/integer/general.p" persistent set hMathInteger.
            return hMathInteger.
        end get.
        private set.

    // Create a single instance of the general math long procedure.
    define protected property hMathLong as handle no-undo
        get():
            // Create single instance for this procedure.
            if not valid-handle(hMathLong) then
                run "OpenEdge/LoadSuite/Procedure/math/long/general.p" persistent set hMathLong.
            return hMathLong.
        end get.
        private set.

    // Create a single instance of the general string long procedure.
    define protected property hStringLong as handle no-undo
        get():
            // Create single instance for this procedure.
            if not valid-handle(hStringLong) then
                run "OpenEdge/LoadSuite/Procedure/string/long/general.p" persistent set hStringLong.
            return hStringLong.
        end get.
        private set.

    // Create a single instance of the general string short procedure.
    define protected property hStringShort as handle no-undo
        get():
            // Create single instance for this procedure.
            if not valid-handle(hStringShort) then
                run "OpenEdge/LoadSuite/Procedure/string/short/general.p" persistent set hStringShort.
            return hStringShort.
        end get.
        private set.

    // Create a single instance of the general temp-table procedure.
    define protected property hTempTable as handle no-undo
        get():
            // Create single instance for this procedure.
            if not valid-handle(hTempTable) then
                run "OpenEdge/LoadSuite/Procedure/temptable/general.p" persistent set hTempTable.
            return hTempTable.
        end get.
        private set.

    constructor LoadSuiteProcService ( ):
        // Constructor can be used to initialize any instance-level data or resources.
    end constructor.

    method public void floatAddition ( input  iNum1 as decimal,
                                       input  iNum2 as decimal,
                                       output oResult as decimal ):
        run "addition" in hMathFloat (iNum1, iNum2, output oResult).
    end method. // floatAddition

    method public void floatSubtraction ( input  iNum1 as decimal,
                                          input  iNum2 as decimal,
                                          output oResult as decimal ):
        run "subtraction" in hMathFloat (iNum1, iNum2, output oResult).
    end method. // floatSubtraction

    method public void floatMultiplication ( input  iNum1 as decimal,
                                             input  iNum2 as decimal,
                                             output oResult as decimal ):
        run "multiplication" in hMathFloat (iNum1, iNum2, output oResult).
    end method. // floatMultiplication

    method public void floatDivision ( input  iNum1 as decimal,
                                       input  iNum2 as decimal,
                                       output oResult as decimal ):
        run "division" in hMathFloat (iNum1, iNum2, output oResult).
    end method. // floatDivision

    method public void integerAddition ( input  iNum1 as integer,
                                         input  iNum2 as integer,
                                         output oResult as integer ):
        run "addition" in hMathInteger (iNum1, iNum2, output oResult).
    end method. // integerAddition

    method public void integerSubtraction ( input  iNum1 as integer,
                                            input  iNum2 as integer,
                                            output oResult as integer ):
        run "subtraction" in hMathInteger (iNum1, iNum2, output oResult).
    end method. // integerSubtraction

    method public void integerMultiplication ( input  iNum1 as integer,
                                               input  iNum2 as integer,
                                               output oResult as integer ):
        run "multiplication" in hMathInteger (iNum1, iNum2, output oResult).
    end method. // integerMultiplication

    method public void integerDivision ( input  iNum1 as integer,
                                         input  iNum2 as integer,
                                         output oResult as integer ):
        run "division" in hMathInteger (iNum1, iNum2, output oResult).
    end method. // integerDivision

    method public void longAddition ( input  iNum1 as int64,
                                      input  iNum2 as int64,
                                      output oResult as int64 ):
        run "addition" in hMathLong (iNum1, iNum2, output oResult).
    end method. // longAddition

    method public void longSubtraction ( input  iNum1 as int64,
                                         input  iNum2 as int64,
                                         output oResult as int64 ):
        run "subtraction" in hMathLong (iNum1, iNum2, output oResult).
    end method. // longSubtraction

    method public void longMultiplication ( input  iNum1 as int64,
                                            input  iNum2 as int64,
                                            output oResult as int64 ):
        run "multiplication" in hMathLong (iNum1, iNum2, output oResult).
    end method. // longMultiplication

    method public void longDivision ( input  iNum1 as int64,
                                      input  iNum2 as int64,
                                      output oResult as int64 ):
        run "division" in hMathLong (iNum1, iNum2, output oResult).
    end method. // longDivision

    method public void stringLongWhatLetter ( input  iLoc as integer,
                                              output oResult as character ):
        run "WhatLetter" in hStringLong (iLoc, output oResult).
    end method. // stringLongWhatLetter

    method public void stringLongWhatWord ( input  iStart as integer,
                                            input  iLength as integer,
                                            output oResult as character ):
        run "WhatWord" in hStringLong (iStart, iLength, output oResult).
    end method. // stringLongWhatWord

    method public void stringShortFindIn ( input  iLetter as character,
                                           output oResult as integer ):
        run "FindIn" in hStringShort (iLetter, output oResult).
    end method. // stringShortFindIn

    method public void stringShortHelloJoin ( input  iWord as character,
                                              output oResult as character ):
        run "HelloJoin" in hStringShort (iWord, output oResult).
    end method. // stringShortHelloJoin

    method public void stringShortWhatLetter ( input  iNum as integer,
                                               output oResult as character ):
        run "WhatLetter" in hStringShort (iNum, output oResult).
    end method. // stringShortWhatLetter

    method public void stringShortWhatWord ( input  iStart as integer,
                                             input  iLength as integer,
                                             output oResult as character ):
        run "WhatWord" in hStringShort (iStart, iLength, output oResult).
    end method. // stringShortWhatWord

    method public void tempTableCreateDynamic ( input  iNumFields as integer,
                                                output oResult as logical ):
        run "CreateDynamic" in hTempTable (iNumFields, output oResult).
    end method. // tempTableCreateDynamic

    method public void tempTableCreateStatic ( input  kTableName as character,
                                               output oResult as logical ):
        run "CreateStatic" in hTempTable (kTableName, output oResult).
    end method. // tempTableCreateStatic

    method public void tempTableAddRecords ( input  iNumToCreate as int64,
                                             output oResult as int64 ):
        run "AddRecords" in hTempTable (iNumToCreate, output oResult).
    end method. // tempTableAddRecords

    method public void tempTableDeleteTable ( output oResult as logical ):
        run "DeleteTable" in hTempTable (output oResult).
    end method. // tempTableDeleteTable

end class.