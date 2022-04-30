module labN;
reg [31:0] entryPoint;
reg RegWrite, clk, ALUSrc, MemRead, MemWrite, Mem2Reg, INT, isbranch, isjump;
reg [2:0] op;

wire [31:0] wd, rd1, rd2, imm, ins, PCp4, jTarget, z, branch, memOut, wb, PCin, PC;
wire zero;

yIF myIF(ins, PC, PCp4, PCin, clk);
yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
yEX myEx(z, zero, rd1, rd2, imm, op, ALUSrc);
yDM myDM(memOut, z, rd2, clk, MemRead, MemWrite);
yWB myWB(wb, z, memOut, Mem2Reg);
yPC myPC(PCin, PC, PCp4, INT, entryPoint, branch, jTarget, zero, isbranch, isjump);

assign wd = wb;

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
            isjump = 0;
            isbranch = 0;
            RegWrite = 0;
            ALUSrc = 1;
            op = 3'b010;
            MemRead = 0;
            MemWrite = 0;
            Mem2Reg = 0;

            //fix
            if (ins[6:0] == 7'h3) //I
            begin
               RegWrite = 1;
               MemRead = 1;
               Mem2Reg = 1;
            end

            if (ins[6:0] == 7'h13) //I
            begin
               RegWrite = 1;
            end

            if (ins[6:0] == 7'h23) //S
            begin
               MemWrite = 1;
            end

            if (ins[6:0] == 7'h33) //R
            begin
              RegWrite = 1;
              ALUSrc = 0;
            end

            if (ins[6:0] == 7'h63) //SB
            begin
              ALUSrc = 0;
              op = 3'b110;
              isbranch = 1;
            end

            if (ins[6:0] == 7'h6F) //UJ
            begin
               RegWrite = 1;
               isjump = 1;
            end
      
            //-----------Execute the ins
            clk = 0; #1;

            //-----------View results
            $display("%h: rd1=%2d rd2=%2d z=%3d zero=%b wb=%2d", ins, rd1, rd2, z, zero, wb);
            //--------------------------------------Prepare for the next ins
        end
   $finish;
   end
endmodule
