module yMux1(z, a, b, c);
	output z;
	input a, b, c;
	wire notC, upper, lower;
	not my_not(notC, c);
	and upperAnd(upper, a, notC);
	and lowerAnd(lower, c, b);
	or my_or(z, upper, lower);
endmodule

module yMux(z, a, b, c);
	parameter SIZE = 2;
	output [SIZE-1:0] z;
	input [SIZE-1:0] a, b;
	input c;
	yMux1 mine[SIZE-1:0] (z, a, b, c);
endmodule

module yMux4to1(z, a0, a1, a2, a3, c);
	parameter SIZE = 2;
	output [SIZE-1:0] z;
	input [SIZE-1:0] a0, a1, a2, a3;
	input [1:0] c;
	
	wire [SIZE-1:0] zLo, zHi;
	yMux #(SIZE) lo(zLo, a0, a1, c[0]);
	yMux #(SIZE) hi(zHi, a2, a3, c[0]);
	yMux #(SIZE) final(z, zLo, zHi, c[1]);
endmodule

module yAdder1(z, cout, a, b, cin);
	output z, cout;
	input a, b, cin;
	xor left_xor(tmp, a, b);
	xor right_xor(z, cin, tmp);
	and left_and(outL, a, b);
	and right_and(outR, tmp, cin);
	or my_or(cout, outR, outL);
endmodule

module yAdder(z, cout, a, b, cin);
	output[31:0] z;
	output cout;
	
	input[31:0] a, b;
	input cin;
	
	wire[31:0] in, out;
	
	yAdder1 mine[31:0](z, out, a, b, in);
	assign in[0] = cin;
	assign in[31:1] = out[30:0];
endmodule

module yArith(z, cout, a, b, ctrl);
	output [31:0] z;
	output cout;
	input [31:0] a, b;
	input ctrl;
	wire [31:0] notB, tmp;
	wire cin;
	assign cin = ctrl;
	not invB[31:0] (notB, b);
	yMux #(32) chooseB(tmp, b, notB, ctrl);
	yAdder arith(z, cout, a, tmp, cin);
endmodule

module yAlu(z, ex, a, b, op);
	input [31:0] a, b;
	input [2:0] op;
	output [31:0] z;
	output ex;
	
	wire [31:0] zAnd, zOr, zArith, slt;
	wire [31:0] tmp;
	
	assign slt[31:1] = 0;
	assign ex = ~(| z);
	
	and andOut[31:0] (zAnd, a, b);
	or orOut[31:0] (zOr, a, b);
	yArith arithOut (zArith, ,a, b, op[2]);
	yMux4to1 #(32) muxOut(z, zAnd, zOr, zArith, slt, op[1:0]);
	
	xor(condition, a[31], b[31]);
	yArith sltArith(tmp, , a, b, 1'b1);
	yMux1 sltMux(slt[0], tmp[31], a[31], condition);
	
endmodule

module yIF(ins, PC, PCp4, PCin, clk);
output [31:0] ins, PC, PCp4;
input [31:0] PCin;
input clk;

wire zero;
wire read, write, enable;
wire [31:0] a, memIn;
wire [2:0] op;
 
register #(32) pc_reg(PC, PCin, clk, enable);
mem insMem(ins, PC, memIn, clk, read, write);
yAlu myAlu(PCp4, zero, a, PC, op);

assign enable = 1'b1;
assign a = 32'h0004;
assign op = 3'b010;
assign read = 1'b1;
assign write = 1'b0;

endmodule

module yID(rd1, rd2, immOut, jTarget, branch, ins, wd, RegWrite, clk);
    output [31:0] rd1, rd2, immOut;
    output [31:0] jTarget;
    output [31:0] branch;

    input [31:0] ins, wd;
    input RegWrite, clk;

    wire [19:0] zeros, ones; // For I-Type and SB-Type
    wire [11:0] zerosj, onesj; // For UJ-Type
    wire [31:0] imm, saveImm; // For S-Type

    rf myRF(rd1, rd2, ins[19:15], ins[24:20], ins[11:7], wd, clk, RegWrite);

    assign imm[11:0] = ins[31:20];
    assign zeros = 20'h00000;
    assign ones = 20'hFFFFF;
    yMux #(20) se(imm[31:12], zeros, ones, ins[31]);

    assign saveImm[11:5] = ins[31:25];
    assign saveImm[4:0] = ins[11:7];

    yMux #(20) saveImmSe(saveImm[31:12], zeros, ones, ins[31]);
    yMux #(32) immSelection(immOut, imm, saveImm, ins[5]);

    assign branch[11] = ins[31];
    assign branch[10] = ins[7];
    assign branch[9:4] = ins[30:25];
    assign branch[3:0] = ins[11:8];
    yMux #(20) bra(branch[31:12], zeros, ones, ins[31]);

    assign zerosj = 12'h000;
    assign onesj = 12'hFFF;
    assign jTarget[19] = ins[31];
    assign jTarget[18:11] = ins[19:12];
    assign jTarget[10] = ins[20];
    assign jTarget[9:0] = ins[30:21];
    yMux #(12) jum(jTarget[31:20], zerosj, onesj, jTarget[19]);

endmodule

module yEX(z, zero, rd1, rd2, imm, op, ALUSrc);
    output [31:0] z;
    output zero;
    input [31:0] rd1, rd2, imm;
    input [2:0] op;
    input ALUSrc;
    wire [31:0] w;

    yMux #(32) mux(w, rd2, imm, ALUSrc);
    yAlu alu(z, zero, rd1, w, op);

endmodule

module yDM(memOut, exeOut, rd2, clk, MemRead, MemWrite);
    output [31:0] memOut;
    input [31:0] exeOut, rd2;
    input clk, MemRead, MemWrite;

    mem dataMemory(memOut, exeOut, rd2, clk, MemRead, MemWrite);

endmodule

module yWB(wb, exeOut, memOut, Mem2Reg);
    output [31:0] wb;
    input [31:0] exeOut, memOut;
    input Mem2Reg;

    yMux #(32) writeback(wb, exeOut, memOut, Mem2Reg);

endmodule

module yPC(PCin, PC, PCp4,INT,entryPoint,branchImm,jImm,zero,isbranch,isjump);
    output [31:0] PCin;
    input [31:0] PC, PCp4, entryPoint, branchImm;
    input [31:0] jImm;
    input INT, zero, isbranch, isjump;
	wire [31:0] branchImmX4, jImmX4, jImmX4PPCp4, bTarget, choiceA, choiceB;
    wire doBranch, zf;

    // Shifting left branchImm twice
    assign branchImmX4[31:2] = branchImm[29:0];
    assign branchImmX4[1:0] = 2'b00;

    // Shifting left jump twice
    assign jImmX4[31:2] = jImm[29:0];
    assign jImmX4[1:0] = 2'b00;

    // adding PC to shifted twice,

    //Replace ? in the yPC module with proper entries.
    yAlu bALU(bTarget, zf, PC, branchImmX4, 3'b010);

    // adding PC to shifted twice, jImm
    //Replace ? in the yPC module with proper entries.
    yAlu jALU(jImmX4PPCp4, zf, PC, jImmX4, 3'b010);

    // deciding to do branch
    and decide_do(doBranch, isbranch, zero);
    yMux #(32) mux1(choiceA, PCp4, bTarget, doBranch);
    yMux #(32) mux2(choiceB, choiceA, jImmX4PPCp4, isjump);
    yMux #(32) mux3(PCin, choiceB, entryPoint, INT);

endmodule

module yC1(isStype, isRtype, isItype, isLw, isjump, isbranch, opCode);
    output isStype, isRtype, isItype, isLw, isjump, isbranch;
    input [6:0] opCode;
    wire lwor, ISselect, JBselect, sbz, sz;
    // opCode
    // lw      0000011
    // I-Type  0010011
    // R-Type  0110011
    // SB-Type 1100011 beq
    // UJ-Type 1101111 jal
    // S-Type  0100011

    // Detect UJ-type
    assign isjump=opCode[3];

    // Detect lw
    or (lwor, opCode[6], opCode[5], opCode[4], opCode[3], opCode[2]); not (isLw, lwor);

    // Select between S-Type and I-Type
    xor (ISselect, opCode[6], opCode[3], opCode[2], opCode[1], opCode[0]);
    and (isStype, ISselect, opCode[5]);
    and (isItype, ISselect, opCode[4]);

    // Detect R-Type
    and (isRtype, opCode[5], opCode[4]);

    // Select between JAL and Branch
    and (JBselect, opCode[6], opCode[5]);
    not (sbz, opCode[3]);
    and (isbranch, JBselect, sbz);
endmodule

module yC2(RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg, 
             isStype, isRtype, isItype, isLw, isjump, isbranch);
    output RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg;
    input isStype, isRtype, isItype, isLw, isjump, isbranch;

    // You need two or gates and 3 assignments;
    nor (ALUSrc, isRtype, isbranch);			
    nor (RegWrite, isStype, isbranch);
    
    assign MemRead = isLw;
    assign MemWrite = isStype;
	assign Mem2Reg = isLw;
endmodule

module yC3(ALUop, isRtype, isbranch);
    output [1:0] ALUop;
    input isRtype, isbranch;
   
    assign ALUop[1] = isRtype;
    assign ALUop[0] = isbranch;
endmodule

module yC4(op, ALUop, funct3);
    output [2:0] op;
    input [2:0] funct3;
    input [1:0] ALUop;

    xor top_xor(top_xor, funct3[2], funct3[1]);
	and top_and(top_and, ALUop[1], top_xor);
	or top_or(op[2], ALUop[0], top_and);
	not top_not(top_not, ALUop[1]);
	not bot_not(bot_not, funct3[1]);
	or bot_or(op[1], top_not, bot_not);
	xor bot_xor(bot_xor, funct3[1], funct3[0]);
	and bot_and(op[0], ALUop[1], bot_xor);
endmodule

module yChip(ins, rd2, wb, entryPoint, INT, clk);
    output [31:0] ins, rd2, wb;
    input [31:0] entryPoint;
    input INT, clk;

    wire [31:0] wd, rd1, imm, PCp4, jTarget, exeOut, branch, memOut, PCin, PC;
    wire zero;
    wire [6:0] opCode;
    wire isStype, isRtype, isItype, isLw, isjump, isbranch;
    wire RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg;
    wire [2:0] op, funct3;
    wire [1:0] ALUop;

    yIF myIF(ins, PC, PCp4, PCin, clk);
    yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
    yEX myEx(exeOut, zero, rd1, rd2, imm, op, ALUSrc);
    yDM myDM(memOut, exeOut, rd2, clk, MemRead, MemWrite);
    yWB myWB(wb, exeOut, memOut, Mem2Reg);
    yPC myPC(PCin, PC, PCp4, INT, entryPoint, branch, jTarget, zero, isbranch, isjump);
    assign opCode = ins[6:0];
    yC1 myC1(isStype, isRtype, isItype, isLw, isjump, isbranch, opCode);
    yC2 myC2(RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg, 
              isStype, isRtype, isItype, isLw, isjump, isbranch);
    yC3 myC3(ALUop, isRtype, isbranch);
    assign funct3=ins[14:12];
    yC4 myC4(op, ALUop, funct3);
    assign wd = wb; 
endmodule

//That's all folks! :)
