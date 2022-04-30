module labM;
reg [31:0] PCin;
reg RegWrite, clk, ALUSrc;
reg [2:0] op;

wire [31:0] wd, rd1, rd2, imm, ins, PCp4, jTarget, z, branch;
wire zero;

yIF myIF(ins, PCp4, PCin, clk);
yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
yEX myEx(z, zero, rd1, rd2, imm, op, ALUSrc);

assign wd = z;

initial
    begin
        PCin = 16'h28;
        repeat (11)
        begin
            clk = 1; #1;
            RegWrite = 0;
            ALUSrc = 1;
            op = 3'b010;
            //fix
            if (ins[6:0] == 7'h3 || ins[6:0] == 7'h13) RegWrite = 1; //I

            if (ins[6:0] == 7'h23) //S, no change
            begin
            end
        
            if (ins[6:0] == 7'h63) //SB
            begin
              ALUSrc = 0;
              op = 3'b110;
            end

            if (ins[6:0] == 7'h6F) RegWrite = 1; //UJ
      
            if (ins[6:0] == 7'h33) //R
            begin
              RegWrite = 1;
              ALUSrc = 0;
            end

            clk = 0; #1;
            #4 $display("%8h: rd1=%d rd2=%d imm=%d jTarget=%d z=%d zero=%b", ins, rd1, rd2, imm, jTarget, z, zero);
            PCin = PCp4;
        end
   $finish;
   end
endmodule
