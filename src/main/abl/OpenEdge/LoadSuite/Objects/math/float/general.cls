 /*------------------------------------------------------------------------
    File        : OpenEdge.LoadSuite.Objects.math.float.general
    Purpose     : Execute and measure performance of OpenEdge MATH functions
    Description : General math functions    
    Author(s)   : Cameron David Wright
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.

block-level on error undo, throw.

/**
  * General DECIMAL math utilities.
  *
  * Provides basic arithmetic operations implemented in ABL for DECIMAL operands.
  * All methods run under `block-level on error undo, throw`, so runtime errors (for
  * example, division by zero) will raise `Progress.Lang.Error` unless handled by
  * callers.
  *
  * @author Cameron David Wright <openedge>
  * @since 1.0
  * @version 1.0
  */
class OpenEdge.LoadSuite.Objects.math.float.general: 
        
    /**
      * Initializes a new instance of `OpenEdge.LoadSuite.Objects.math.float.general`.
      *
      * No state is maintained; construction is effectively a no-op beyond base initialization.
      */
    constructor public general (  ):
       
        super ().
        
    end constructor.

    /**
      * Adds two DECIMAL values.
      *
      * @param iNum1 First addend.
      * @param iNum2 Second addend.
      * @return Sum of `iNum1` and `iNum2`.
      * @throws Progress.Lang.Error If an arithmetic error occurs.
      */
    method public decimal addition( input iNum1 as decimal, input iNum2 as decimal ):
        
        define variable result as decimal no-undo.

        assign result = (iNum1 + iNum2).

        return result.

    end method.

    /**
      * Subtracts the second DECIMAL from the first.
      *
      * @param iNum1 Minuend.
      * @param iNum2 Subtrahend.
      * @return Difference `iNum1 - iNum2`.
      * @throws Progress.Lang.Error If an arithmetic error occurs.
      */
    method public decimal subtraction(  input iNum1 as decimal, input iNum2 as decimal  ):
        
        define variable result as decimal no-undo.

        assign result = (iNum1 - iNum2).

        return result.

    end method.

    /**
      * Multiplies two DECIMAL values.
      *
      * @param iNum1 Multiplicand.
      * @param iNum2 Multiplier.
      * @return Product `iNum1 * iNum2`.
      * @throws Progress.Lang.Error If an arithmetic error occurs.
      */
    method public decimal multiplication(  input iNum1 as decimal, input iNum2 as decimal  ):
        
        define variable result as decimal no-undo.

        assign result = (iNum1 * iNum2).

        return result.

    end method.
    
    /**
      * Divides the first DECIMAL by the second.
      *
      * Note: Division by zero will raise an error under the class error policy.
      *
      * @param iNum1 Dividend.
      * @param iNum2 Divisor.
      * @return Quotient `iNum1 / iNum2`.
      * @throws Progress.Lang.Error If `iNum2` is zero or another arithmetic error occurs.
      */
    method public decimal division(  input iNum1 as decimal, input iNum2 as decimal  ):
        
        define variable result as decimal no-undo.

        assign result = (iNum1 / iNum2).

        return result.

    end method.
        
    /**
      * Releases resources held by this instance.
      *
      * No explicit cleanup is required for this stateless class.
      */
    destructor public general ( ):

    end destructor.

end class.