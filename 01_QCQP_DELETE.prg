/*~BB~************************************************************************
      *                                                                      *
      *  Copyright Notice:  (c) 1983 Laboratory Information Systems &        *
      *                              Technology, Inc.                        *
      *       Revision      (c) 1984-1995 Cerner Corporation                 *
      *                                                                      *
      *  Cerner (R) Proprietary Rights Notice:  All rights reserved.         *
      *  This material contains the valuable properties and trade secrets of *
      *  Cerner Corporation of Kansas City, Missouri, United States of       *
      *  America (Cerner), embodying substantial creative efforts and        *
      *  confidential information, ideas and expressions, no part of which   *
      *  may be reproduced or transmitted in any form or by any means, or    *
      *  retained in any storage or retrieval system without the express     *
      *  written permission of Cerner.                                       *
      *                                                                      *
      *  Cerner is a registered mark of Cerner Corporation.                  *
      *                                                                      *
  ~BE~***********************************************************************/
 
/*****************************************************************************
 
        Source file name:	01_QCQP_DELETE.prg
        Object name:		01_QCQP_DELETE
        Request #:
 
        Product:                PathNet General Lab
        Product Team:           PathNet General Lab
 
        Program purpose:        Delete QC/QP numbers
 
*****************************************************************************/
 
 
;~DB~************************************************************************
;    *                      GENERATED MODIFICATION CONTROL LOG              *
;    ************************************************************************
;    *                                                                      *
;    *Mod Date     Engineer             Comment                             *
;    *--- -------- -------------------- ----------------------------------- *
;    *001 6/2/2021 bp053685             Initial                 									*
;~DE~************************************************************************
 
drop program 01_QCQP_DELETE go
create program 01_QCQP_DELETE
 
prompt
	"Output to File/Printer/MINE" = "MINE"
	, "QC Number" = 0
	, "QP Number" = 0
	, "Control" = 0
	, "Service Resource" = 0
 
with OUTDEV, QCNUM, QPNUM, CONTROL, SERVICERESOURCE
 
; Missing one of the fields
if (($QCNUM = NULL) or ($QPNUM = NULL) or ($Control = NULL) or ($ServiceResource = NULL))
	set error_code = 1
 	set error_message = "Missing one or more required fields"
 	go to exit_script
endif
 
; Initialize variables
declare QC_Accession = vc
declare QP_Accession = vc
declare lotID = f8
declare error_code = i4 with protect, noconstant(0)
declare error_message = vc
 
; Set QC_Accession variable
Select into "nl:"
from accession a
where accession_id = $QCNUM
detail
	QC_Accession = concat(substring(6,2,  a.accession ), "-", substring(12, 7, a.accession))
with nocounter
 
; Set QP_Accession variable
Select into "nl:"
from accession a
where accession_id = $QPNUM
detail
	QP_Accession = concat(substring(6,2,  a.accession ), "-", substring(12, 7, a.accession))
with nocounter
 
; Set lot id variable
Select into "nl:"
from control_lot cl
where cl.control_id = $Control
detail
	lotID = cl.LOT_ID
with nocounter
 
; ******* Error Checking *********
 
; Test if QC and QP numbers aren't associated to chosen control and SR
Select into "nl:"
from resource_accession_r
where service_resource_cd = $ServiceResource
and control_id = $Control
and accession_id in($QCNUM, $QPNUM)
 
if (curqual != 2)
	set error_code = 3
	set error_message = "QC/QP numbers aren't associated to the chosen Control/SR pair"
	go to exit_script
endif
 
Select into "nl:"
from resource_lot_r rl
where rl.service_resource_cd = $ServiceResource
and rl.lot_id = lotID
 
if (curqual != 1)
	set error_code = 4
	set error_message = "Lot id and service_resource are not associated"
	go to exit_script
endif
 
 
; Delete Statements if all errors pass
Delete from resource_accession_r where service_resource_cd=$ServiceResource and control_id=$Control
and accession_id in ($QCNUM, $QPNUM)
 
Delete from resource_lot_r where service_resource_cd=$ServiceResource and lot_id= lotID
 
Delete from accession where accession_id in ($QCNUM, $QPNUM)
 
#exit_script
 
if (error_code = 0)
	SELECT INTO $OUTDEV
	head page
		rpt_row = 0
	detail
		rpt_row = 3
		row rpt_row, col 20, call print(build2("***QC/QP Delete***"))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2("Service Resource: ",$ServiceResource))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2("Control: ",$Control))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2("QC Number, ",QC_Accession, ", has been deleted"))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2("QP Number, ",QP_Accession, ", has been deleted"))
 
elseif (error_code > 0)
		SELECT INTO $OUTDEV
	head page
		rpt_row = 0
	detail
		rpt_row = 3
		row rpt_row, col 20, call print(build2("***QC/QP Delete***"))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2("ERROR"))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2("Code: ", error_code))
		rpt_row = rpt_row + 1
		row rpt_row, col 30, call print(build2(error_message))
endif
 
end
go
 
