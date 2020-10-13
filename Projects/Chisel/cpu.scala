// This file is where all of the CPU components are assembled into the whole CPU
// ***Note: details for implementation are in lab report instead of comments since there was a lot to explain, and for good coding style

// necessary packages
package dinocpu

import chisel3._
import chisel3.util._

/**
 * The main CPU definition that hooks up all of the other components.
 *
 * For more information, see section 4.6 of Patterson and Hennessy
 * This follows figure 4.49
 */

class PipelinedCPU(implicit val conf: CPUConfig) extends Module {
  val io = IO(new CoreIO)

  // Bundles defining the pipeline registers and control structures

  // Everything in the register between IF and ID stages
  class IFIDBundle extends Bundle {
    val instruction = UInt(32.W)
    val pc          = UInt(32.W)
    val pcplusfour  = UInt(32.W)
  }

  // Control signals used in EX stage
  class EXControl extends Bundle {
    val add       = Bool()
    val immediate = Bool()
    val alusrc1   = UInt(2.W)
    val branch    = Bool()
    val jump      = UInt(2.W)
  }

  // Signals used in MEM stage
  // Given but needed to complete by adding the 3 signals
  class MControl extends Bundle {
	val memread = Bool()
	val memwrite = Bool()
	
	val maskmode = UInt(2.W)
	val sext = Bool()
	val taken = Bool()	
  }

  // Control signals used in WB stage (given)
  class WBControl extends Bundle {
	val toreg = UInt(2.W)
	val regwrite = Bool()
  }

  // Everything in the register between ID and EX stages
  class IDEXBundle extends Bundle {
    val rs1       = UInt(5.W)    
    val rs2       = UInt(5.W)
    val readdata1 = UInt(32.W)
    val readdata2 = UInt(32.W)
    val sextImm = UInt(32.W)
    val writereg  = UInt(5.W)
    val funct7    = UInt(7.W)
    val funct3    = UInt(3.W)	
    val pc        = UInt(32.W)
    val pcplusfour= UInt(32.W)
    
  }
  
  // IDEX Control Bundle: created to separate the control signals from the IDEX regular signals
  class IDEXControlBundle extends Bundle {
    val excontrol = new EXControl		
    val mcontrol  = new MControl
    val wbcontrol = new WBControl 
	
  }

  // Everything in the register between EX and MEM stages
  class EXMEMBundle extends Bundle {
    val readdata2 = UInt(32.W)
    val aluresult = UInt(32.W)
    val writereg  = UInt(5.W)	
    val nextpc    = UInt(32.W)
    val pcplusfour = UInt(32.W)	
  }
  
  // EXMEM Control Bundle: created to separate the control signals from the EXMEM regular signals
  class EXMEMControlBundle extends Bundle {
    val mcontrol  = new MControl
    val wbcontrol = new WBControl
  }

  // Everything in the register between MEM and WB stages
  class MEMWBBundle extends Bundle {
    val aluresult = UInt(32.W)
    val readdata  = UInt(32.W)
    val writereg  = UInt(5.W)
    val pcplusfour= UInt(32.W)
  }

  // MEMWB Control Bundle: created to separate the control signals from the MEMWB regular signals
  class MEMWBControlBundle extends Bundle {
    val wbcontrol = new WBControl
  }

  // All of the structures required (given) 
  val pc         = RegInit(0.U)
  val control    = Module(new Control())
  val branchCtrl = Module(new BranchControl())
  val registers  = Module(new RegisterFile())
  val aluControl = Module(new ALUControl())
  val alu        = Module(new ALU())
  val immGen     = Module(new ImmediateGenerator())
  val pcPlusFour = Module(new Adder())
  val branchAdd  = Module(new Adder())
  val forwarding = Module(new ForwardingUnit())  //pipelined only
  val hazard     = Module(new HazardUnit())      //pipelined only
  val (cycleCount, _) = Counter(true.B, 1 << 30)

  val if_id      = RegInit(0.U.asTypeOf(new IFIDBundle))
  val id_ex      = RegInit(0.U.asTypeOf(new IDEXBundle))
  val ex_mem     = RegInit(0.U.asTypeOf(new EXMEMBundle))
  val mem_wb     = RegInit(0.U.asTypeOf(new MEMWBBundle))

  // declared new bundles that we added
  val id_ex_control	= RegInit(0.U.asTypeOf(new IDEXControlBundle))
  val ex_mem_control 	= RegInit(0.U.asTypeOf(new EXMEMControlBundle))  
  val mem_wb_control 	= RegInit(0.U.asTypeOf(new MEMWBControlBundle))

  printf("Cycle=%d ", cycleCount)

  // Forward declaration of wires that connect different stages

  // From memory back to fetch. Since we don't decide whether to take a branch or not until the memory stage.
  val next_pc = Wire(UInt(32.W))

  // For wb back to other stages
  val write_data = Wire(UInt(32.W))

  /////////////////////////////////////////////////////////////////////////////
  // FETCH STAGE
  /////////////////////////////////////////////////////////////////////////////

  // Note: This comes from the memory stage!
  // Only update the pc if the pcwrite flag is enabled		
  pc := MuxCase(0.U, Array(
                (hazard.io.pcwrite === 0.U) -> pcPlusFour.io.result,
                (hazard.io.pcwrite === 1.U) -> next_pc,
                (hazard.io.pcwrite === 2.U) -> pc))

  // Send the PC to the instruction memory port to get the instruction (given)
  io.imem.address := pc

  // Get the PC + 4 (given)
  pcPlusFour.io.inputx := pc
  pcPlusFour.io.inputy := 4.U


  // Fill the IF/ID register if we are not bubbling IF/ID
  // otherwise, leave the IF/ID register *unchanged*
  when (~hazard.io.ifid_bubble) {
    if_id.instruction := io.imem.instruction
    if_id.pc          := pc
    if_id.pcplusfour  := pcPlusFour.io.result
  }
  
  printf(p"IF/ID: $if_id\n")

  /////////////////////////////////////////////////////////////////////////////
  // ID STAGE
  /////////////////////////////////////////////////////////////////////////////

  val rs1 = if_id.instruction(19,15)
  val rs2 = if_id.instruction(24,20)

  // Send input from this stage to hazard detection unit
  hazard.io.rs1 := rs1
  hazard.io.rs2 := rs2  
  
  // Send opcode to control
  control.io.opcode := if_id.instruction(6,0)


  // Send register numbers to the register file
  registers.io.readreg1 := rs1
  registers.io.readreg2 := rs2


  // Send the instruction to the immediate generator
  immGen.io.instruction := if_id.instruction

  // FIll the id_ex register 
  id_ex.rs1 := rs1
  id_ex.rs2 := rs2

  id_ex.readdata1 := registers.io.readdata1
  id_ex.readdata2 := registers.io.readdata2

  id_ex.writereg 	:= if_id.instruction(11,7)
  id_ex.funct7 		:= if_id.instruction(31,25)
  id_ex.funct3		:= if_id.instruction(14,12) 

  id_ex.sextImm 	:= immGen.io.sextImm
  id_ex.pc 		:= if_id.pc
  id_ex.pcplusfour 	:= if_id.pcplusfour

 
  // Set the execution control signals
  id_ex_control.excontrol.add 		:= control.io.add
  id_ex_control.excontrol.immediate 	:= control.io.immediate
  id_ex_control.excontrol.alusrc1 	:= control.io.alusrc1
  id_ex_control.excontrol.branch 	:= control.io.branch
  id_ex_control.excontrol.jump 		:= control.io.jump


  // Set the memory control signals 
  id_ex_control.mcontrol.memread 	:= control.io.memread
  id_ex_control.mcontrol.memwrite 	:= control.io.memwrite
  id_ex_control.mcontrol.maskmode 	:= if_id.instruction(13,12) 
  id_ex_control.mcontrol.sext 		:= ~if_id.instruction(14)
  id_ex_control.mcontrol.taken 		:= branchCtrl.io.taken 
  
  
  // Set the writeback control signals
  id_ex_control.wbcontrol.toreg 	:= control.io.toreg
  id_ex_control.wbcontrol.regwrite 	:= control.io.regwrite

   // flush if needed
  when (hazard.io.ifid_flush) {
    if_id.instruction 			:= 0.U
    if_id.pc         		 	:= 0.U
    if_id.pcplusfour  			:= 0.U
    id_ex_control.wbcontrol.regwrite    := 0.U
  }
  
  printf("DASM(%x)\n", if_id.instruction)
  printf(p"ID/EX: $id_ex\n")
  printf("writereg:%d\n", id_ex.writereg)

  /////////////////////////////////////////////////////////////////////////////
  // EX STAGE
  /////////////////////////////////////////////////////////////////////////////

  // Set the inputs to the hazard detection unit from this stage (SKIP FOR PART I)
  hazard.io.idex_rd      := id_ex.writereg
  hazard.io.idex_memread := id_ex_control.mcontrol.memread

  // Set the input to the forwarding unit from this stage (SKIP FOR PART I)
  forwarding.io.rs1 := id_ex.rs1
  forwarding.io.rs2 := id_ex.rs2

  // Connect the ALU control wires (line 45 of single-cycle/cpu.scala)
  aluControl.io.add       := id_ex_control.excontrol.add
  aluControl.io.immediate := id_ex_control.excontrol.immediate
  aluControl.io.funct7    := id_ex.funct7
  aluControl.io.funct3    := id_ex.funct3


  // Insert the forward inputx mux here (SKIP FOR PART I)
  // upper left mux, followed formatting from single cycle cpu
  val forwardA_mux = Wire(UInt(32.W))
  forwardA_mux  := MuxCase(0.U, Array(
	(forwarding.io.forwardA === 0.U) -> id_ex.readdata1,
      	(forwarding.io.forwardA === 1.U) -> ex_mem.aluresult,
      	(forwarding.io.forwardA === 2.U) -> write_data))


  // Insert the ALU inputx mux here (line 59 of single-cycle/cpu.scala)
  // upper right mux
  val alu_forwardA = Wire(UInt(32.W))
  alu_forwardA := MuxCase(0.U, Array(
    	(id_ex_control.excontrol.alusrc1 === 0.U) -> forwardA_mux,
    	(id_ex_control.excontrol.alusrc1 === 1.U) -> 0.U,
    	(id_ex_control.excontrol.alusrc1 === 2.U) -> id_ex.pc
  ))

  alu.io.inputx := alu_forwardA


  // Insert forward inputy mux here (SKIP FOR PART I)
  // lower left mux
  val forwardB_mux = Wire(UInt(32.W))
  forwardB_mux := MuxCase(0.U, Array(
       	(forwarding.io.forwardB === 0.U) -> id_ex.readdata2,
  	(forwarding.io.forwardB === 1.U) -> ex_mem.aluresult,
 	(forwarding.io.forwardB === 2.U) -> write_data))

  
  val forwardA = forwarding.io.forwardA
  val forwardB = forwarding.io.forwardB


  // Input y mux (line 66 of single-cycle/cpu.scala)
  val alu_inputy 	= Wire(UInt())  
  alu.io.inputy 	:= Mux(id_ex_control.excontrol.immediate, id_ex.sextImm, forwardB_mux)
  alu_inputy 		:= forwardB_mux

  // Connect the branch control wire (line 54 of single-cycle/cpu.scala)
  branchCtrl.io.branch := id_ex_control.excontrol.branch
  branchCtrl.io.funct3 := id_ex.funct3
  branchCtrl.io.inputx := forwardA_mux
  branchCtrl.io.inputy := forwardB_mux
  
  
  // Set the ALU operation
  alu.io.operation := aluControl.io.operation


  // Connect the branchAdd unit
  branchAdd.io.inputx := id_ex.pc
  branchAdd.io.inputy := id_ex.sextImm


  // Set the EX/MEM register values
  ex_mem.readdata2 	:= alu_inputy
  ex_mem.aluresult 	:= alu.io.result
  ex_mem.writereg 	:= id_ex.writereg
  ex_mem.nextpc 	:= id_ex.pc
  ex_mem.pcplusfour 	:= id_ex.pcplusfour

  // mem control
  ex_mem_control.mcontrol.memread 	:= id_ex_control.mcontrol.memread
  ex_mem_control.mcontrol.memwrite 	:= id_ex_control.mcontrol.memwrite
  ex_mem_control.mcontrol.maskmode 	:= id_ex_control.mcontrol.maskmode 
  ex_mem_control.mcontrol.sext 		:= id_ex_control.mcontrol.sext
  ex_mem_control.mcontrol.taken 	:= id_ex_control.mcontrol.taken
  
  //wbcontrol
  ex_mem_control.wbcontrol.toreg 	:= id_ex_control.wbcontrol.toreg
  ex_mem_control.wbcontrol.regwrite 	:= id_ex_control.wbcontrol.regwrite

  // Calculate whether which PC we should use and set the taken flag (line 92 in single-cycle/cpu.scala)
  when (branchCtrl.io.taken || id_ex_control.excontrol.jump === 2.U) {
    ex_mem.nextpc := branchAdd.io.result
	ex_mem_control.mcontrol.taken := true.B
  }
  .elsewhen (id_ex_control.excontrol.jump === 3.U) {
    ex_mem.nextpc := alu.io.result & Cat(Fill(31, 1.U), 0.U)
	ex_mem_control.mcontrol.taken := true.B
  }
  .otherwise {
    ex_mem.nextpc 			:= 0.U
    ex_mem_control.mcontrol.taken  	:= false.B
  }

  // Check for bubbles
  when (hazard.io.idex_bubble) {	
	id_ex_control.mcontrol.memwrite := 0.U
	id_ex_control.mcontrol.memread := 0.U
	id_ex_control.wbcontrol.toreg := 0.U
	id_ex_control.wbcontrol.regwrite := 0.U	
	id_ex_control.excontrol.branch := 0.U
	id_ex_control.excontrol.jump := 0.U
	id_ex_control.excontrol.alusrc1 := 0.U
	id_ex_control.excontrol.immediate := 0.U
	id_ex_control.excontrol.add := 0.U
  }

  printf(p"EX/MEM: $ex_mem\n")
  printf("writereg:%d\n", ex_mem.writereg)

  /////////////////////////////////////////////////////////////////////////////
  // MEM STAGE
  /////////////////////////////////////////////////////////////////////////////

  // Set data memory IO (line 71 of single-cycle/cpu.scala)
  io.dmem.address   := ex_mem.aluresult
  io.dmem.writedata := ex_mem.readdata2
  io.dmem.memread   := ex_mem_control.mcontrol.memread
  io.dmem.memwrite  := ex_mem_control.mcontrol.memwrite
  io.dmem.maskmode  := ex_mem_control.mcontrol.maskmode
  io.dmem.sext      := ex_mem_control.mcontrol.sext


  // Send next_pc back to the fetch stage
  next_pc := ex_mem.nextpc  


  // Send input signals to the hazard detection unit (SKIP FOR PART I)
  hazard.io.exmem_taken := ex_mem_control.mcontrol.taken

  // Send input signals to the forwarding unit (SKIP FOR PART I)
  forwarding.io.exmemrd := ex_mem.writereg
  forwarding.io.exmemrw := ex_mem_control.wbcontrol.regwrite

  // Wire the MEM/WB register
  mem_wb.aluresult  := ex_mem.aluresult
  mem_wb.readdata   := io.dmem.readdata
  mem_wb.writereg   := ex_mem.writereg
  mem_wb.pcplusfour := ex_mem.pcplusfour

  printf(p"MEM/WB: $mem_wb\n")
  
  //wbcontrol
  mem_wb_control.wbcontrol.toreg 	:= ex_mem_control.wbcontrol.toreg
  mem_wb_control.wbcontrol.regwrite 	:= ex_mem_control.wbcontrol.regwrite
  
  // Check for bubbles
  when (hazard.io.exmem_bubble) {
	ex_mem_control.mcontrol.memwrite 	:= 0.U
	ex_mem_control.mcontrol.memread 	:= 0.U
	ex_mem_control.wbcontrol.toreg 		:= 0.U
	ex_mem_control.wbcontrol.regwrite 	:= 0.U	
	ex_mem_control.mcontrol.taken 		:= 0.U
  }

  printf("writereg:%d\n", mem_wb.writereg)
  printf("toreg:%d\n", id_ex_control.wbcontrol.regwrite)
  printf("regwrite:%d\n", id_ex_control.wbcontrol.regwrite)
  
  /////////////////////////////////////////////////////////////////////////////
  // WB STAGE
  /////////////////////////////////////////////////////////////////////////////

  // Set the writeback data mux (line 78 single-cycle/cpu.scala)
  write_data := MuxCase(mem_wb.aluresult, Array(
                       (mem_wb_control.wbcontrol.toreg === 0.U) -> mem_wb.aluresult,
                       (mem_wb_control.wbcontrol.toreg === 1.U) -> mem_wb.readdata,
                       (mem_wb_control.wbcontrol.toreg === 2.U) -> mem_wb.pcplusfour))

  // Write the data to the register file
  registers.io.writereg  := mem_wb.writereg
  registers.io.writedata := write_data

  when (mem_wb.writereg =/= 0.U) {
		registers.io.wen := mem_wb_control.wbcontrol.regwrite
  }	.otherwise {
		registers.io.wen := 0.U
  }
  
  // Set the input signals for the forwarding unit (SKIP FOR PART I)
  forwarding.io.memwbrd := mem_wb.writereg
  forwarding.io.memwbrw := mem_wb_control.wbcontrol.regwrite

  
  printf("---------------------------------------------\n")
}
