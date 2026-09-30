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

    DOH Mapping: sample.map

    This is the service interface for the LoadSuite application. This has a 
    direct correlation to the DOH mapping defined in loadsuite.map

    When you add/modify this file make sure to update the corresponding DOH 
    mapping in loadsuite.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.

class OpenEdge.LoadSuite.Interface.LoadSuiteFuncService
    use-widget-pool
    final
:

    { OpenEdge/LoadSuite/Common/include/FunctionForwards.i "in super"}
    
    // Access the service-level logging manager.
    define protected property oLogger as ILogWriter no-undo
        get():
            // Create single logger instance for this class.
            if not valid-object(oLogger) then
                assign oLogger = LoggerBuilder:GetLogger(this-object:getClass()).
            return oLogger.
        end get.
        private set.
/*
    define private variable hMathFloat   as handle no-undo.
    define private variable hMathInteger as handle no-undo.
    define private variable hMathLong    as handle no-undo.
    define private variable hStringLong  as handle no-undo.
    define private variable hStringShort as handle no-undo.
    define private variable hTempTable   as handle no-undo.

    constructor LoadSuiteFuncService ( ):

        run "Function/math/float/general.p" persistent set hMathFloat no-error.
        session:add-super-procedure(hMathFloat).

        run "Function/math/integer/general.p" persistent set hMathInteger no-error.
        session:add-super-procedure(hMathInteger).

        run "Function/math/long/general.p" persistent set hMathLong no-error.
        session:add-super-procedure(hMathLong).

        run "Function/string/long/general.p" persistent set hStringLong no-error.
        session:add-super-procedure(hStringLong).

        run "Function/string/short/general.p" persistent set hStringShort no-error.
        session:add-super-procedure(hStringShort).

        run "Function/temptable/general.p" persistent set hTempTable no-error.
        session:add-super-procedure(hTempTable).

    end constructor.

    destructor LoadSuiteFuncService ( ):

        delete object hMathFloat   no-error.
        delete object hMathInteger no-error.
        delete object hMathLong    no-error.
        delete object hStringLong  no-error.
        delete object hStringShort no-error.
        delete object hTempTable   no-error.

    end destructor.

    method public void floatAddition ( input  iNum1 as decimal,
                                       input  iNum2 as decimal,
                                       output oResult as decimal ):

        oResult = addition(iNum1, iNum2).

    end method. // floatAddition

    method public void floatSubtraction ( input  iNum1 as decimal,
                                          input  iNum2 as decimal,
                                          output oResult as decimal ):

        oResult = subtraction(iNum1, iNum2).

    end method. // floatSubtraction

    method public void floatMultiplication ( input  iNum1 as decimal,
                                             input  iNum2 as decimal,
                                             output oResult as decimal ):

        oResult = multiplication(iNum1, iNum2).

    end method. // floatMultiplication

    method public void floatDivision ( input  iNum1 as decimal,
                                       input  iNum2 as decimal,
                                       output oResult as decimal ):

        oResult = division(iNum1, iNum2).

    end method. // floatDivision

    method public void integerAddition ( input  iNum1 as integer,
                                         input  iNum2 as integer,
                                         output oResult as integer ):

        oResult = addition(iNum1, iNum2).

    end method. // integerAddition

    method public void integerSubtraction ( input  iNum1 as integer,
                                            input  iNum2 as integer,
                                            output oResult as integer ):

        oResult = subtraction(iNum1, iNum2).

    end method. // integerSubtraction

    method public void integerMultiplication ( input  iNum1 as integer,
                                               input  iNum2 as integer,
                                               output oResult as integer ):

        oResult = multiplication(iNum1, iNum2).

    end method. // integerMultiplication

    method public void integerDivision ( input  iNum1 as integer,
                                         input  iNum2 as integer,
                                         output oResult as integer ):

        oResult = division(iNum1, iNum2).

    end method. // integerDivision

    method public void longAddition ( input  iNum1 as int64,
                                      input  iNum2 as int64,
                                      output oResult as int64 ):

        oResult = addition(iNum1, iNum2).

    end method. // longAddition

    method public void longSubtraction ( input  iNum1 as int64,
                                         input  iNum2 as int64,
                                         output oResult as int64 ):

        oResult = subtraction(iNum1, iNum2).

    end method. // longSubtraction

    method public void longMultiplication ( input  iNum1 as int64,
                                            input  iNum2 as int64,
                                            output oResult as int64 ):

        oResult = multiplication(iNum1, iNum2).

    end method. // longMultiplication

    method public void longDivision ( input  iNum1 as int64,
                                      input  iNum2 as int64,
                                      output oResult as int64 ):

        oResult = division(iNum1, iNum2).

    end method. // longDivision

    method public void stringLongWhatLetter ( input  iLoc as integer,
                                              output oResult as character ):

        oResult = WhatLetter(iLoc).

    end method. // stringLongWhatLetter

    method public void stringLongWhatWord ( input  iStart as integer,
                                            input  iLength as integer,
                                            output oResult as character ):

        oResult = WhatWord(iStart, iLength).

    end method. // stringLongWhatWord

    method public void stringShortFindIn ( input  iLetter as character,
                                           output oResult as integer ):

        oResult = FindIn(iLetter).

    end method. // stringShortFindIn

    method public void stringShortHelloJoin ( input  iWord as character,
                                              output oResult as character ):

        oResult = HelloJoin(iWord).

    end method. // stringShortHelloJoin

    method public void stringShortWhatLetter ( input  iNum as integer,
                                               output oResult as character ):

        oResult = WhatLetter(iNum).

    end method. // stringShortWhatLetter

    method public void stringShortWhatWord ( input  iStart as integer,
                                             input  iLength as integer,
                                             output oResult as character ):

        oResult = WhatWord(iStart, iLength).

    end method. // stringShortWhatWord

    method public void tempTableCreateDynamic ( input  iNumFields as integer,
                                                output oResult as logical ):

        oResult = CreateDynamic(iNumFields).

    end method. // tempTableCreateDynamic

    method public void tempTableCreateStatic ( input  kTableName as character,
                                               output oResult as logical ):

        oResult = CreateStatic(kTableName).

    end method. // tempTableCreateStatic

    method public void tempTableAddRecords ( input  iNumToCreate as int64,
                                             output oResult as int64 ):

        oResult = AddRecords(iNumToCreate).

    end method. // tempTableAddRecords

    method public void tempTableDeleteTable ( output oResult as logical ):

        oResult = DeleteTable().

    end method. // tempTableDeleteTable
*/
end class.