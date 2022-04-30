module labN;
reg [31:0] entryPoint;
reg clk, INT;
reg [2:0] op;

wire [31:0] wd, rd1, rd2, imm, ins, PCp4, jTarget, exeOut, branch, memOut, wb, PCin, PC;
wire zero;
wire [6:0] opCode;
wire isStype, isRtype, isItype, isLw, isjump, isbranch;
wire RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg;

yIF myIF(ins, PC, PCp4, PCin, clk);
yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
yEX myEx(exeOut, zero, rd1, rd2, imm, op, ALUSrc);
yDM myDM(memOut, exeOut, rd2, clk, MemRead, MemWrite);
yWB myWB(wb, exeOut, memOut, Mem2Reg);

assign wd = wb; 
yPC myPC(PCin, PC, PCp4, INT, entryPoint, branch, jTarget, zero, isbranch, isjump);

assign opCode = ins[6:0];
yC1 myC1(isStype, isRtype, isItype, isLw, isjump, isbranch, opCode);
yC2 myC2(RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg, 
            isStype, isRtype, isItype, isLw, isjump, isbranch);

initial
    begin
        //------------------------------------Entry point
        entryPoint = 32'h28; 
        INT = 1;
        #1;
        //------------------------------------Run program
        repeat (43) begin
            //---------------------------------Fetch an ins
            clk = 1; #1;
            INT = 0;
            // Temporarily set
            op = 3'b010;

            //fix
            if (ins[6:0] == 7'h3) //I
            begin
            end

            if (ins[6:0] == 7'h13) //I
            begin
            end

            if (ins[6:0] == 7'h23) //S
            begin
            end

            if (ins[6:0] == 7'h33) //R
            begin
            end

            if (ins[6:0] == 7'h63) //SB
            begin
              op = 3'b110;
            end

            if (ins[6:0] == 7'h6F) //UJ
            begin
            end
      
            //-----------Execute the ins
            clk = 0; #1;

            //-----------View results
            $display("%h: rd1=%2d rd2=%2d exeOut=%3d zero=%b wb=%2d", ins, rd1, rd2, exeOut, zero, wb);
            //--------------------------------------Prepare for the next ins
        end
   $finish;
   end
endmodule
