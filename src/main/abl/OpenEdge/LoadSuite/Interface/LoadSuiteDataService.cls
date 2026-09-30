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

    DOH Mapping: data.map

    This is the service interface for the LoadSuite application. This has a
    direct correlation to the DOH mapping defined in loadsuite.map

    When you add/modify this file make sure to update the corresponding DOH
    mapping in data.map
------------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Logging.ILogWriter.
using OpenEdge.Logging.LoggerBuilder.
using Progress.Json.ObjectModel.JsonObject.

class OpenEdge.LoadSuite.Interface.LoadSuiteDataService
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

    // Create a single instance of the general record read class.
    define protected property oRecordRead as OpenEdge.LoadSuite.Objects.record.read.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oRecordRead) then
                assign oRecordRead = new OpenEdge.LoadSuite.Objects.record.read.general().
            return oRecordRead.
        end get.
        private set.

    // Create a single instance of the general record creation class.
    define protected property oRecordCreate as OpenEdge.LoadSuite.Objects.record.create.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oRecordCreate) then
                assign oRecordCreate = new OpenEdge.LoadSuite.Objects.record.create.general().
            return oRecordCreate.
        end get.
        private set.

    // Create a single instance of the general record update class.
    define protected property oRecordUpdate as OpenEdge.LoadSuite.Objects.record.update.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oRecordUpdate) then
                assign oRecordUpdate = new OpenEdge.LoadSuite.Objects.record.update.general().
            return oRecordUpdate.
        end get.
        private set.

    // Create a single instance of the general record delete class.
    define protected property oRecordDelete as OpenEdge.LoadSuite.Objects.record.delete.general no-undo
        get():
            // Create single instance for this class.
            if not valid-object(oRecordDelete) then
                assign oRecordDelete = new OpenEdge.LoadSuite.Objects.record.delete.general().
            return oRecordDelete.
        end get.
        private set.

    constructor LoadSuiteDataService ( ):
        // Constructor can be used to initialize any instance-level data or resources.
    end constructor.

    /** ********** Data CRUD Methods ********** */

    method public void createBenefits ( input  inEmpNum as int64,
                                        output oBenefitsResult as JsonObject ):
        assign oBenefitsResult = oRecordCreate:createBenefits(inEmpNum).
    end method. // createBenefits

    method public void createBillTo ( input  inCustNum as int64,
                                      input  inBillToID as int64,
                                      input  inName as character,
                                      output oBillToResult as JsonObject ):
        assign oBillToResult = oRecordCreate:createBillTo(inCustNum, inBillToID, inName).
    end method. // createBillTo

    method public void createBin ( input  inBinNum as int64,
                                   input  inBinName as character,
                                   output oBinResult as JsonObject ):
        assign oBinResult = oRecordCreate:createBin(inBinNum, inBinName).
    end method. // createBin

    method public void createCustomer ( input  inCustNum as int64,
                                        input  inName as character,
                                        input  inComments as character,
                                        output oCustomerResult as JsonObject ):
        assign oCustomerResult = oRecordCreate:createCustomer(inCustNum, inName, inComments).
    end method. // createCustomer

    method public void createDepartment ( input  inDeptCode as character,
                                          input  inDeptName as character,
                                          output oDepartmentResult as JsonObject ):
        assign oDepartmentResult = oRecordCreate:createDepartment(inDeptCode, inDeptName).
    end method. // createDepartment

    method public void createEmployee ( input  inEmpNum as int64,
                                        input  inFirstName as character,
                                        input  inLastName as character,
                                        output oEmployeeResult as JsonObject ):
        assign oEmployeeResult = oRecordCreate:createEmployee(inEmpNum, inFirstName, inLastName).
    end method. // createEmployee

    method public void createFamily ( input  inEmpNum as int64,
                                      input  inRelativeName as character,
                                      output oFamilyResult as JsonObject ):
        assign oFamilyResult = oRecordCreate:createFamily(inEmpNum, inRelativeName).
    end method. // createFamily

    method public void createFeedback ( input  inDepartment as character,
                                        input  inComments as character,
                                        output oFeedbackResult as JsonObject ):
        assign oFeedbackResult = oRecordCreate:createFeedback(inDepartment, inComments).
    end method. // createFeedback

    method public void createInventoryTrans ( input  inInvTransNum as int64,
                                              output oInventoryTransResult as JsonObject ):
        assign oInventoryTransResult = oRecordCreate:createInventoryTrans(inInvTransNum).
    end method. // createInventoryTrans

    method public void createInvoice ( input  inInvoiceNum as int64,
                                       input  inAmount as decimal,
                                       output oInvoiceResult as JsonObject ):
        assign oInvoiceResult = oRecordCreate:createInvoice(inInvoiceNum, inAmount).
    end method. // createInvoice

    method public void createItem ( input  inItemNum as int64,
                                    input  inItemName as character,
                                    input  inCatDescription as character,
                                    output oItemResult as JsonObject ):
        assign oItemResult = oRecordCreate:createItem(inItemNum, inItemName, inCatDescription).
    end method. // createItem

    method public void createLocalDefault ( input  inLocalDefNum as int64,
                                            output oLocalDefaultResult as JsonObject ):
        assign oLocalDefaultResult = oRecordCreate:createLocalDefault(inLocalDefNum).
    end method. // createLocalDefault

    method public void createOrder ( input  inOrderNum as int64,
                                     input  inCustNum as int64,
                                     output oOrderResult as JsonObject ):
        assign oOrderResult = oRecordCreate:createOrder(inOrderNum, inCustNum).
    end method. // createOrder

    method public void createOrderLine ( input  inLineNum as int64,
                                         input  inOrderNum as int64,
                                         output oOrderLineResult as JsonObject ):
        assign oOrderLineResult = oRecordCreate:createOrderLine(inLineNum, inOrderNum).
    end method. // createOrderLine

    method public void createPOLine ( input  inLineNum as int64,
                                      input  inPONum as int64,
                                      output oPOLineResult as JsonObject ):
        assign oPOLineResult = oRecordCreate:createPOLine(inLineNum, inPONum).
    end method. // createPOLine

    method public void createPurchaseOrder ( input  inPONum as int64,
                                             output oPurchaseOrderResult as JsonObject ):
        assign oPurchaseOrderResult = oRecordCreate:createPurchaseOrder(inPONum).
    end method. // createPurchaseOrder

    method public void createRefCall ( input  inCallNum as int64, 
                                       input  inCustNum as int64,
                                       input  inParent as character,
                                       output oRefCallResult as JsonObject ):
        assign oRefCallResult = oRecordCreate:createRefCall(inCallNum, inCustNum, inParent).
    end method. // createRefCall

    method public void createSalesRep ( input  inSalesRep as character,
                                        input  inRepName as character,
                                        output oSalesRepResult as JsonObject ):
        assign oSalesRepResult = oRecordCreate:createSalesRep(inSalesRep, inRepName).
    end method. // createSalesRep

    method public void createShipTo ( input  inCustNum as int64,
                                      input  inShipToID as int64,
                                      input  inName as character,
                                      input  inComments as character,
                                      output oShipToResult as JsonObject ):
        assign oShipToResult = oRecordCreate:createShipTo(inCustNum, inShipToID, inName, inComments).
    end method. // createShipTo

    method public void createState ( input  inState as character,
                                     input  inStateName as character,
                                     output oStateResult as JsonObject ):
        assign oStateResult = oRecordCreate:createState(inState, inStateName).
    end method. // createState

    method public void createSupplier ( input  inSupplierIDNum as int64,
                                        input  inName as character,
                                        input  inShipAmount as int64,
                                        input  inComments as character,
                                        output oSupplierResult as JsonObject ):
        assign oSupplierResult = oRecordCreate:createSupplier(inSupplierIDNum, inName, inShipAmount, inComments).
    end method. // createSupplier

    method public void createSupplierItemXref ( input  inItemNum as int64,
                                                input  inSupplierIDNum as int64,
                                                output oSupplierItemXrefResult as JsonObject ):
        assign oSupplierItemXrefResult = oRecordCreate:createSupplierItemXref(inItemNum, inSupplierIDNum).
    end method. // createSupplierItemXref

    method public void createTimeSheet ( input  inDayRecorded as date,
                                         input  inEmpNum as int64,
                                         output oTimesheetResult as JsonObject ):
        assign oTimesheetResult = oRecordCreate:createTimeSheet(inDayRecorded, inEmpNum).
    end method. // createTimeSheet

    method public void createVacation ( input  inEmpNum as int64,
                                        input  inStartDate as date,
                                        output oVacationResult as JsonObject ):
        assign oVacationResult = oRecordCreate:createVacation(inEmpNum, inStartDate).
    end method. // createVacation

    method public void createWarehouse ( input  inWarehouseNum as int64,
                                         input  inWarehouseName as character,
                                         output oWarehouseResult as JsonObject ):
        assign oWarehouseResult = oRecordCreate:createWarehouse(inWarehouseNum, inWarehouseName).
    end method. // createWarehouse

    method public void readBenefits ( input  inEmpNum as int64,
                                      output oBenefitsResult as JsonObject ):
        assign oBenefitsResult = oRecordRead:readBenefits(inEmpNum).
    end method. // readBenefits

    method public void readBillTo ( input  inCustNum as int64,
                                    input  inBillToID as int64,
                                    output oBillToResult as JsonObject ):
        assign oBillToResult = oRecordRead:readBillTo(inCustNum, inBillToID).
    end method. // readBillTo

    method public void readBin ( input  inBinNum as int64,
                                 output oBinResult as JsonObject ):
        assign oBinResult = oRecordRead:readBin(inBinNum).
    end method. // readBin

    method public void readCustomer ( input  inCustNum as int64,
                                      output oCustomerResult as JsonObject ):
        assign oCustomerResult = oRecordRead:readCustomer(inCustNum).
    end method. // readCustomer

    method public void readDepartment ( input  inDeptCode as character,
                                        output oDepartmentResult as JsonObject ):
        assign oDepartmentResult = oRecordRead:readDepartment(inDeptCode).
    end method. // readDepartment

    method public void readEmployee ( input  inEmpNum as int64,
                                      output oEmployeeResult as JsonObject ):
        assign oEmployeeResult = oRecordRead:readEmployee(inEmpNum).
    end method. // readEmployee

    method public void readFamily ( input  inEmpNum as int64,
                                    input  inRelativeName as character,
                                    output oFamilyResult as JsonObject ):
        assign oFamilyResult = oRecordRead:readFamily(inEmpNum, inRelativeName).
    end method. // readFamily

    method public void readFeedback ( input  inDepartment as character,
                                      output oFeedbackResult as JsonObject ):
        assign oFeedbackResult = oRecordRead:readFeedback(inDepartment).
    end method. // readFeedback

    method public void readInventoryTrans ( input  inInvTransNum as int64,
                                            output oInventoryTransResult as JsonObject ):
        assign oInventoryTransResult = oRecordRead:readInventoryTrans(inInvTransNum).
    end method. // readInventoryTrans

    method public void readInvoice ( input  inInvoiceNum as int64,
                                     output oInvoiceResult as JsonObject ):
        assign oInvoiceResult = oRecordRead:readInvoice(inInvoiceNum).
    end method. // readInvoice

    method public void readItem ( input  inItemNum as int64,
                                  output oItemResult as JsonObject ):
        assign oItemResult = oRecordRead:readItem(inItemNum).
    end method. // readItem

    method public void readLocalDefault ( input  inLocalDefNum as int64,
                                          output oLocalDefaultResult as JsonObject ):
        assign oLocalDefaultResult = oRecordRead:readLocalDefault(inLocalDefNum).
    end method. // readLocalDefault

    method public void readCustOrder ( input  inCustNum as int64,
                                       input  inOrderNum as int64,
                                       output oCustOrderResult as JsonObject ):
        assign oCustOrderResult = oRecordRead:readCustOrder(inCustNum, inOrderNum).
    end method. // readCustOrder

    method public void readOrder ( input  inOrderNum as int64,
                                   output oOrderResult as JsonObject ):
        assign oOrderResult = oRecordRead:readOrder(inOrderNum).
    end method. // readOrder

    method public void readOrderLine ( input  inOrderNum as int64,
                                       input  inLineNum as int64,
                                       output oOrderLineResult as JsonObject ):
        assign oOrderLineResult = oRecordRead:readOrderLine(inOrderNum, inLineNum).
    end method. // readOrderLine

    method public void readPOLine ( input  inPONum as int64,
                                    input  inLineNum as int64,
                                    output oPOLineResult as JsonObject ):
        assign oPOLineResult = oRecordRead:readPOLine(inPONum, inLineNum).
    end method. // readPOLine

    method public void readPurchaseOrder ( input  inPONum as int64,
                                           output oPurchaseOrderResult as JsonObject ):
        assign oPurchaseOrderResult = oRecordRead:readPurchaseOrder(inPONum).
    end method. // readPurchaseOrder

    method public void readRefCall ( input  inCallNum as int64,
                                     output oRefCallResult as JsonObject ):
        assign oRefCallResult = oRecordRead:readRefCall(inCallNum).
    end method. // readRefCall

    method public void readSalesRep ( input  inSalesRep as character,
                                      output oSalesRepResult as JsonObject ):
        assign oSalesRepResult = oRecordRead:readSalesRep(inSalesRep).
    end method. // readSalesRep

    method public void readShipTo ( input  inCustNum as int64,
                                    input  inShipToID as int64,
                                    output oShipToResult as JsonObject ):
        assign oShipToResult = oRecordRead:readShipTo(inCustNum, inShipToID).
    end method. // readShipTo

    method public void readState ( input  inState as character,
                                   output oStateResult as JsonObject ):
        assign oStateResult = oRecordRead:readState(inState).
    end method. // readState

    method public void readSupplier ( input  inSupplierIDNum as int64,
                                      output oSupplierResult as JsonObject ):
        assign oSupplierResult = oRecordRead:readSupplier(inSupplierIDNum).
    end method. // readSupplier

    method public void readSupplierItemXref ( input  inSupplierIDNum as int64,
                                              input  inItemNum as int64,
                                              output oSupplierItemXrefResult as JsonObject ):
        assign oSupplierItemXrefResult = oRecordRead:readSupplierItemXref(inSupplierIDNum, inItemNum).
    end method. // readSupplierItemXref

    method public void readTimeSheet ( input  inEmpNum as int64,
                                       input  inDayRecorded as date,
                                       output oTimesheetResult as JsonObject ):
        assign oTimesheetResult = oRecordRead:readTimeSheet(inEmpNum, inDayRecorded).
    end method. // readTimeSheet

    method public void readVacation ( input  inEmpNum as int64,
                                      input  inStartDate as date,
                                      output oVacationResult as JsonObject ):
        assign oVacationResult = oRecordRead:readVacation(inEmpNum, inStartDate).
    end method. // readVacation

    method public void readWarehouse ( input  inWarehouseNum as int64,
                                       output oWarehouseResult as JsonObject ):
        assign oWarehouseResult = oRecordRead:readWarehouse(inWarehouseNum).
    end method. // readWarehouse

    method public void updateBenefits ( input  inEmpNum as int64,
                                        output oBenefitsResult as JsonObject ):
        assign oBenefitsResult = oRecordUpdate:updateBenefits(inEmpNum).
    end method. // updateBenefits

    method public void updateBillTo ( input  inCustNum as int64,
                                      input  inBillToID as int64,
                                      input  inName as character,
                                      output oBillToResult as JsonObject ):
        assign oBillToResult = oRecordUpdate:updateBillTo(inCustNum, inBillToID, inName).
    end method. // updateBillTo

    method public void updateBin ( input  inBinNum as int64,
                                   input  inBinName as character,
                                   output oBinResult as JsonObject ):
        assign oBinResult = oRecordUpdate:updateBin(inBinNum, inBinName).
    end method. // updateBin

    method public void updateCustomer ( input  inCustNum as int64,
                                        input  inName as character,
                                        input  inComments as character,
                                        input  inPhone as character,
                                        input  inContact as character,
                                        input  inEmailAddress as character,
                                        input  inTerms as character,
                                        output oCustomerResult as JsonObject ):
        assign oCustomerResult = oRecordUpdate:updateCustomer(inCustNum, inName, inComments, inPhone, inContact, inEmailAddress, inTerms).
    end method. // updateCustomer

    method public void updateDepartment ( input  inDeptCode as character,
                                          input  inDeptName as character,
                                          output oDepartmentResult as JsonObject ):
        assign oDepartmentResult = oRecordUpdate:updateDepartment(inDeptCode, inDeptName).
    end method. // updateDepartment

    method public void updateEmployee ( input  inEmpNum as int64,
                                        input  inFirstName as character,
                                        input  inLastName as character,
                                        input  inDeptCode as character,
                                        input  inPosition as character,
                                        output oEmployeeResult as JsonObject ):
        assign oEmployeeResult = oRecordUpdate:updateEmployee(inEmpNum, inFirstName, inLastName, inDeptCode, inPosition).
    end method. // updateEmployee

    method public void updateFamily ( input  inEmpNum as int64,
                                      input  inRelativeName as character,
                                      output oFamilyResult as JsonObject ):
        assign oFamilyResult = oRecordUpdate:updateFamily(inEmpNum, inRelativeName).
    end method. // updateFamily

    method public void updateFeedback ( input  inDepartment as character,
                                        input  inComments as character,
                                        output oFeedbackResult as JsonObject ):
        assign oFeedbackResult = oRecordUpdate:updateFeedback(inDepartment, inComments).
    end method. // updateFeedback

    method public void updateInventoryTrans ( input  inInvTransNum as int64,
                                              output oInventoryTransResult as JsonObject ):
        assign oInventoryTransResult = oRecordUpdate:updateInventoryTrans(inInvTransNum).
    end method. // updateInventoryTrans

    method public void updateInvoice ( input  inInvoiceNum as int64,
                                       input  inAmount as decimal,
                                       output oInvoiceResult as JsonObject ):
        assign oInvoiceResult = oRecordUpdate:updateInvoice(inInvoiceNum, inAmount).
    end method. // updateInvoice

    method public void updateItem ( input  inItemNum as int64,
                                    input  inItemName as character,
                                    input  inCatDescription as character,
                                    input  inCategory1 as character,
                                    input  inCategory2 as character,
                                    output oItemResult as JsonObject ):
        assign oItemResult = oRecordUpdate:updateItem(inItemNum, inItemName, inCatDescription, inCategory1, inCategory2).
    end method. // updateItem

    method public void updateLocalDefault ( input  inLocalDefNum as int64,
                                            output oLocalDefaultResult as JsonObject ):
        assign oLocalDefaultResult = oRecordUpdate:updateLocalDefault(inLocalDefNum).
    end method. // updateLocalDefault

    method public void updateCustomerOrder ( input  inCustNum as int64,
                                             input  inOrderNum as int64,
                                             input  inInstructions as char,
                                             input  inCarrier as character,
                                             input  inTerms as character,
                                             input  inOrderStatus as character,
                                             output oCustOrderResult as JsonObject ):
        assign oCustOrderResult = oRecordUpdate:updateCustomerOrder(inCustNum, inOrderNum, inInstructions, inCarrier, inTerms, inOrderStatus).
    end method. // updateCustomerOrder

    method public void updateOrder ( input  inOrderNum as int64,
                                     input  inInstructions as char,
                                     input  inCarrier as character,
                                     input  inTerms as character,
                                     input  inOrderStatus as character,
                                     output oOrderResult as JsonObject ):
        assign oOrderResult = oRecordUpdate:updateOrder(inOrderNum, inInstructions, inCarrier, inTerms, inOrderStatus).
    end method. // updateOrder

    method public void updateOrderLine ( input  inOrderNum as int64,
                                         input  inLineNum as int64,
                                         input  inOrderLineStatus as character,
                                         output oOrderLineResult as JsonObject ):
        assign oOrderLineResult = oRecordUpdate:updateOrderLine(inOrderNum, inLineNum, inOrderLineStatus).
    end method. // updateOrderLine

    method public void updatePOLine ( input  inPONum as int64,
                                      input  inLineNum as int64,
                                      output oPOLineResult as JsonObject ):
        assign oPOLineResult = oRecordUpdate:updatePOLine(inPONum, inLineNum).
    end method. // updatePOLine

    method public void updatePurchaseOrder ( input  inPONum as int64,
                                             output oPurchaseOrderResult as JsonObject ):
        assign oPurchaseOrderResult = oRecordUpdate:updatePurchaseOrder(inPONum).
    end method. // updatePurchaseOrder

    method public void updateRefCall ( input  inCallNum as int64,
                                       input  inCustNum as int64,
                                       input  inParent as character,
                                       output oRefCallResult as JsonObject ):
        assign oRefCallResult = oRecordUpdate:updateRefCall(inCallNum, inCustNum, inParent).
    end method. // updateRefCall

    method public void updateSalesRep ( input  inSalesRep as character,
                                        input  inRepName as character,
                                        input  inRegion as character,
                                        output oSalesRepResult as JsonObject ):
        assign oSalesRepResult = oRecordUpdate:updateSalesRep(inSalesRep, inRepName, inRegion).
    end method. // updateSalesRep

    method public void updateShipTo ( input  inCustNum as int64,
                                      input  inShipToID as int64,
                                      input  inComments as character,
                                      input  inName as character,
                                      output oShipToResult as JsonObject ):
        assign oShipToResult = oRecordUpdate:updateShipTo(inCustNum, inShipToID, inComments, inName).
    end method. // updateShipTo

    method public void updateState ( input  inState as character,
                                     input  inStateName as character,
                                     output oStateResult as JsonObject ):
        assign oStateResult = oRecordUpdate:updateState(inState, inStateName).
    end method. // updateState

    method public void updateSupplier ( input  inSupplierIDNum as int64,
                                        input  inName as character,
                                        input  inShipAmount as int64,
                                        input  inComments as character,
                                        output oSupplierResult as JsonObject ):
        assign oSupplierResult = oRecordUpdate:updateSupplier(inSupplierIDNum, inName, inShipAmount, inComments).
    end method. // updateSupplier

    method public void updateSupplierItemXref ( input  inSupplierIDNum as int64,
                                                input  inItemNum as int64,
                                                output oSupplierItemXrefResult as JsonObject ):
        assign oSupplierItemXrefResult = oRecordUpdate:updateSupplierItemXref(inSupplierIDNum, inItemNum).
    end method. // updateSupplierItemXref

    method public void updateTimeSheet ( input  inEmpNum as int64,
                                         input  inDayRecorded as date,
                                         output oTimesheetResult as JsonObject ):
        assign oTimesheetResult = oRecordUpdate:updateTimeSheet(inEmpNum, inDayRecorded).
    end method. // updateTimeSheet

    method public void updateVacation ( input  inEmpNum as int64,
                                        input  inStartDate as date,
                                        output oVacationResult as JsonObject ):
        assign oVacationResult = oRecordUpdate:updateVacation(inEmpNum, inStartDate).
    end method. // updateVacation

    method public void updateWarehouse ( input  inWarehouseNum as int64,
                                         input  inWarehouseName as character,
                                         input  inAddress as character,
                                         input  inCity as character,
                                         input  inState as character,
                                         input  inPhone as character,
                                         output oWarehouseResult as JsonObject ):
        assign oWarehouseResult = oRecordUpdate:updateWarehouse(inWarehouseNum, inWarehouseName, inAddress, inCity, inState, inPhone).
    end method. // updateWarehouse

    method public void deleteBenefits( input  inEmpNum as int64,
                                       output oBenefitsResult as JsonObject ):
        assign oBenefitsResult = oRecordDelete:deleteBenefits(inEmpNum).
      end method. // deleteBenefits

    method public void deleteBillTo( input  inCustNum as int64,
                                     input  inBillToID as int64,
                                     output oBillToResult as JsonObject ):
        assign oBillToResult = oRecordDelete:deleteBillTo(inCustNum, inBillToID).
      end method. // deleteBillTo

    method public void deleteBin( input  inBinNum as int64,
                                  output oBinResult as JsonObject ):
        assign oBinResult = oRecordDelete:deleteBin(inBinNum).
      end method. // deleteBin

    method public void deleteCustomer( input  inCustNum as int64,
                                       output oCustomerResult as JsonObject ):
        assign oCustomerResult = oRecordDelete:deleteCustomer(inCustNum).
      end method. // deleteCustomer

    method public void deleteDepartment( input  inDeptCode as character,
                                         output oDepartmentResult as JsonObject ):
        assign oDepartmentResult = oRecordDelete:deleteDepartment(inDeptCode).
      end method. // deleteDepartment

    method public void deleteEmployee( input  inEmpNum as int64,
                                       output oEmployeeResult as JsonObject ):
        assign oEmployeeResult = oRecordDelete:deleteEmployee(inEmpNum).
      end method. // deleteEmployee

    method public void deleteFamily( input  inEmpNum as int64,
                                     input  inRelativeName as character,
                                     output oFamilyResult as JsonObject ):
        assign oFamilyResult = oRecordDelete:deleteFamily(inEmpNum, inRelativeName).
      end method. // deleteFamily

    method public void deleteFeedback( input  inDepartment as character,
                                       output oFeedbackResult as JsonObject ):
        assign oFeedbackResult = oRecordDelete:deleteFeedback(inDepartment).
      end method. // deleteFeedback

    method public void deleteInventoryTrans( input  inInvTransNum as int64,
                                             output oInventoryTransResult as JsonObject ):
        assign oInventoryTransResult = oRecordDelete:deleteInventoryTrans(inInvTransNum).
      end method. // deleteInventoryTrans

    method public void deleteInvoice( input  inInvoiceNum as int64,
                                      output oInvoiceResult as JsonObject ):
        assign oInvoiceResult = oRecordDelete:deleteInvoice(inInvoiceNum).
      end method. // deleteInvoice

    method public void deleteItem( input  inItemNum as int64,
                                   output oItemResult as JsonObject ):
        assign oItemResult = oRecordDelete:deleteItem(inItemNum).
      end method. // deleteItem

    method public void deleteLocalDefault( input  inLocalDefNum as int64,
                                           output oLocalDefaultResult as JsonObject ):
        assign oLocalDefaultResult = oRecordDelete:deleteLocalDefault(inLocalDefNum).
      end method. // deleteLocalDefault

    method public void deleteOrder( input  inOrderNum as int64,
                                    output oOrderResult as JsonObject ):
        assign oOrderResult = oRecordDelete:deleteOrder(inOrderNum).
      end method. // deleteOrder

    method public void deleteOrderLine( input  inOrderNum as int64,
                                        input  inLineNum as int64,
                                        output oOrderLineResult as JsonObject ):
        assign oOrderLineResult = oRecordDelete:deleteOrderLine(inOrderNum, inLineNum).
      end method. // deleteOrderLine

    method public void deletePOLine( input  inPONum as int64,
                                     input  inLineNum as int64,
                                     output oPOLineResult as JsonObject ):
        assign oPOLineResult = oRecordDelete:deletePOLine(inPONum, inLineNum).
      end method. // deletePOLine

    method public void deletePurchaseOrder( input  inPONum as int64,
                                            output oPurchaseOrderResult as JsonObject ):
        assign oPurchaseOrderResult = oRecordDelete:deletePurchaseOrder(inPONum).
      end method. // deletePurchaseOrder

    method public void deleteRefCall( input  inCallNum as int64,
                                      output oRefCallResult as JsonObject ):
        assign oRefCallResult = oRecordDelete:deleteRefCall(inCallNum).
      end method. // deleteRefCall

    method public void deleteSalesRep( input  inSalesRep as character,
                                       output oSalesRepResult as JsonObject ):
        assign oSalesRepResult = oRecordDelete:deleteSalesRep(inSalesRep).
      end method. // deleteSalesRep

    method public void deleteShipTo( input  inCustNum as int64,
                                     input  inShipToID as int64,
                                     output oShipToResult as JsonObject ):
        assign oShipToResult = oRecordDelete:deleteShipTo(inCustNum, inShipToID).
      end method. // deleteShipTo

    method public void deleteState( input  inState as character,
                                    output oStateResult as JsonObject ):
        assign oStateResult = oRecordDelete:deleteState(inState).
      end method. // deleteState

    method public void deleteSupplier( input  inSupplierIDNum as int64,
                                       output oSupplierResult as JsonObject ):
        assign oSupplierResult = oRecordDelete:deleteSupplier(inSupplierIDNum).
      end method. // deleteSupplier

    method public void deleteSupplierItemXref( input  inSupplierIDNum as int64,
                                               input  inItemNum as int64,
                                               output oSupplierItemXrefResult as JsonObject ):
        assign oSupplierItemXrefResult = oRecordDelete:deleteSupplierItemXref(inSupplierIDNum, inItemNum).
      end method. // deleteSupplierItemXref

    method public void deleteTimeSheet( input  inEmpNum as int64,
                                        input  inDayRecorded as date,
                                        output oTimesheetResult as JsonObject ):
        assign oTimesheetResult = oRecordDelete:deleteTimeSheet(inEmpNum, inDayRecorded).
      end method. // deleteTimeSheet

    method public void deleteVacation( input  inEmpNum as int64,
                                       input  inStartDate as date,
                                       output oVacationResult as JsonObject ):
        assign oVacationResult = oRecordDelete:deleteVacation(inEmpNum, inStartDate).
      end method. // deleteVacation

    method public void deleteWarehouse( input  inWarehouseNum as int64,
                                        output oWarehouseResult as JsonObject ):
        assign oWarehouseResult = oRecordDelete:deleteWarehouse(inWarehouseNum).
      end method. // deleteWarehouse

    method public void createAuditHeader ( input  inAuditKey as int64,
                                           input  inAuditName as character,
                                           input  inAuditType as character,
                                           output oAuditHeaderResult as JsonObject ):
        assign oAuditHeaderResult = oRecordCreate:createAuditHeader(inAuditKey, inAuditName, inAuditType).
    end method. // createAuditHeader

    method public void createAuditDetail ( input  inAuditKey as int64,
                                           input  inAuditEntity as character,
                                           input  inBeforeValue as character,
                                           input  inAfterValue as character,
                                           output oAuditDetailResult as JsonObject ):
        assign oAuditDetailResult = oRecordCreate:createAuditDetail(inAuditKey, inAuditEntity, inBeforeValue, inAfterValue).
    end method. // createAuditDetail

    method public void createContextHeader ( input  inContextId as character,
                                             input  inUserId as character,
                                             input  inProductCode as character,
                                             output oContextHeaderResult as JsonObject ):
        assign oContextHeaderResult = oRecordCreate:createContextHeader(inContextId, inUserId, inProductCode).
    end method. // createContextHeader

    method public void createContextDetail ( input  inContextId as character,
                                             input  inPropertyName as character,
                                             input  inPropertyValue as character,
                                             output oContextDetailResult as JsonObject ):
        assign oContextDetailResult = oRecordCreate:createContextDetail(inContextId, inPropertyName, inPropertyValue).
    end method. // createContextDetail

    method public void createReplQueue ( input  inSequence as int64,
                                         input  inEventType as character,
                                         input  inSrcTable as character,
                                         output oReplQueueResult as JsonObject ):
        assign oReplQueueResult = oRecordCreate:createReplQueue(inSequence, inEventType, inSrcTable).
    end method. // createReplQueue

    method public void createSystemFile ( input  inSystemId as character,
                                          input  inCompanyName as character,
                                          output oSystemFileResult as JsonObject ):
        assign oSystemFileResult = oRecordCreate:createSystemFile(inSystemId, inCompanyName).
    end method. // createSystemFile

    method public void readAuditHeader ( input  inAuditKey as int64,
                                         output oAuditHeaderResult as JsonObject ):
        assign oAuditHeaderResult = oRecordRead:readAuditHeader(inAuditKey).
    end method. // readAuditHeader

    method public void readAuditDetail ( input  inAuditKey as int64,
                                         input  inAuditEntity as character,
                                         output oAuditDetailResult as JsonObject ):
        assign oAuditDetailResult = oRecordRead:readAuditDetail(inAuditKey, inAuditEntity).
    end method. // readAuditDetail

    method public void readContextHeader ( input  inContextId as character,
                                           output oContextHeaderResult as JsonObject ):
        assign oContextHeaderResult = oRecordRead:readContextHeader(inContextId).
    end method. // readContextHeader

    method public void readContextDetail ( input  inContextId as character,
                                           input  inPropertyName as character,
                                           output oContextDetailResult as JsonObject ):
        assign oContextDetailResult = oRecordRead:readContextDetail(inContextId, inPropertyName).
    end method. // readContextDetail

    method public void readReplQueue ( input  inSequence as int64,
                                       output oReplQueueResult as JsonObject ):
        assign oReplQueueResult = oRecordRead:readReplQueue(inSequence).
    end method. // readReplQueue

    method public void readSystemFile ( input  inSystemId as character,
                                        output oSystemFileResult as JsonObject ):
        assign oSystemFileResult = oRecordRead:readSystemFile(inSystemId).
    end method. // readSystemFile

    method public void updateAuditHeader ( input  inAuditKey as int64,
                                           input  inAuditName as character,
                                           input  inAuditType as character,
                                           output oAuditHeaderResult as JsonObject ):
        assign oAuditHeaderResult = oRecordUpdate:updateAuditHeader(inAuditKey, inAuditName, inAuditType).
    end method. // updateAuditHeader

    method public void updateAuditDetail ( input  inAuditKey as int64,
                                           input  inAuditEntity as character,
                                           input  inBeforeValue as character,
                                           input  inAfterValue as character,
                                           output oAuditDetailResult as JsonObject ):
        assign oAuditDetailResult = oRecordUpdate:updateAuditDetail(inAuditKey, inAuditEntity, inBeforeValue, inAfterValue).
    end method. // updateAuditDetail

    method public void updateContextHeader ( input  inContextId as character,
                                             input  inUserId as character,
                                             input  inProductCode as character,
                                             output oContextHeaderResult as JsonObject ):
        assign oContextHeaderResult = oRecordUpdate:updateContextHeader(inContextId, inUserId, inProductCode).
    end method. // updateContextHeader

    method public void updateContextDetail ( input  inContextId as character,
                                             input  inPropertyName as character,
                                             input  inPropertyValue as character,
                                             output oContextDetailResult as JsonObject ):
        assign oContextDetailResult = oRecordUpdate:updateContextDetail(inContextId, inPropertyName, inPropertyValue).
    end method. // updateContextDetail

    method public void updateReplQueue ( input  inSequence as int64,
                                         input  inEventType as character,
                                         input  inSrcTable as character,
                                         output oReplQueueResult as JsonObject ):
        assign oReplQueueResult = oRecordUpdate:updateReplQueue(inSequence, inEventType, inSrcTable).
    end method. // updateReplQueue

    method public void updateSystemFile ( input  inSystemId as character,
                                          input  inCompanyName as character,
                                          output oSystemFileResult as JsonObject ):
        assign oSystemFileResult = oRecordUpdate:updateSystemFile(inSystemId, inCompanyName).
    end method. // updateSystemFile

    method public void deleteAuditHeader( input  inAuditKey as int64,
                                          output oAuditHeaderResult as JsonObject ):
        assign oAuditHeaderResult = oRecordDelete:deleteAuditHeader(inAuditKey).
      end method. // deleteAuditHeader

    method public void deleteAuditDetail( input  inAuditKey as int64,
                                          input  inAuditEntity as character,
                                          output oAuditDetailResult as JsonObject ):
        assign oAuditDetailResult = oRecordDelete:deleteAuditDetail(inAuditKey, inAuditEntity).
      end method. // deleteAuditDetail

    method public void deleteContextHeader( input  inContextId as character,
                                            output oContextHeaderResult as JsonObject ):
        assign oContextHeaderResult = oRecordDelete:deleteContextHeader(inContextId).
      end method. // deleteContextHeader

    method public void deleteContextDetail( input  inContextId as character,
                                            input  inPropertyName as character,
                                            output oContextDetailResult as JsonObject ):
        assign oContextDetailResult = oRecordDelete:deleteContextDetail(inContextId, inPropertyName).
      end method. // deleteContextDetail

    method public void deleteReplQueue( input  inSequence as int64,
                                        output oReplQueueResult as JsonObject ):
        assign oReplQueueResult = oRecordDelete:deleteReplQueue(inSequence).
      end method. // deleteReplQueue

    method public void deleteSystemFile( input  inSystemId as character,
                                         output oSystemFileResult as JsonObject ):
        assign oSystemFileResult = oRecordDelete:deleteSystemFile(inSystemId).
      end method. // deleteSystemFile

end class.

