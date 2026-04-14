class uvm_cpu_coverage extends uvm_subscriber#(uvm_cpu_transaction);
    `uvm_component_utils(uvm_cpu_coverage)

    bit [15:0] cmd_in;
    instr_t instr_set;
    bit [2:0] Rn, Rd, Rm;
    bit [1:0] sh_op;
    bit [7:0] imm8;
    bit V, N, Z;
    bit [15:0] expected_out;

    covergroup op_cov;
        cp_instr: coverpoint instr_set {
            bins mov_imm_hit   = {INSTR_MOV_IMM};
            bins mov_shift_hit = {INSTR_MOV_SHIFT};
            bins add_hit       = {INSTR_ADD};
            bins cmp_hit       = {INSTR_CMP};
            bins and_hit       = {INSTR_AND};
            bins mvn_hit       = {INSTR_MVN};
        }
    endgroup

    covergroup reg_cov;
        cp_Rd: coverpoint Rd { bins rd_regs[] = {[0:7]}; }
        cp_Rn: coverpoint Rn { bins rn_regs[] = {[0:7]}; }
        cp_Rm: coverpoint Rm { bins rm_regs[] = {[0:7]}; }
    endgroup

    covergroup shift_cov;
        cp_sh_op: coverpoint sh_op {
            bins no_shift = {2'b00};
            bins lsl      = {2'b01};
            bins lsr      = {2'b10};
            bins asr      = {2'b11};
        }
    endgroup

    covergroup imm8_cov;
        cp_imm8: coverpoint imm8 {
            bins zero     = {8'h00};
            bins max_pos  = {8'h7F};
            bins min_neg  = {8'h80};
            bins all_ones = {8'hFF};
        }
    endgroup

    covergroup flag_cov;
        cp_V: coverpoint V {
            bins ovf_clear = {1'b0};
            bins ovf_set   = {1'b1};
        }
        cp_N: coverpoint N {
            bins neg_clear = {1'b0};
            bins neg_set   = {1'b1};
        }
        cp_Z: coverpoint Z {
            bins zero_clear = {1'b0};
            bins zero_set   = {1'b1};
        }
    endgroup

    covergroup out_cov;
        cp_out: coverpoint expected_out {
            bins zero     = {16'h0000};
            bins all_ones = {16'hFFFF};
            bins max_pos  = {16'h7FFF};
            bins min_neg  = {16'h8000};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        op_cov = new();
        reg_cov = new();
        shift_cov = new();
        imm8_cov = new();
        flag_cov = new();
        out_cov = new();
    endfunction

    function void write(uvm_cpu_transaction t);
        if (t.instr != 0) begin  // Instruction loaded
            cmd_in = t.instr;
            instr_set = instr_t'(cmd_in[15:11]);
            Rn = cmd_in[10:8];
            Rd = cmd_in[7:5];
            Rm = cmd_in[2:0];
            sh_op = cmd_in[4:3];
            imm8 = cmd_in[7:0];

            op_cov.sample();
            reg_cov.sample();
            shift_cov.sample();
            if (instr_set == INSTR_MOV_IMM)
                imm8_cov.sample();
        end else begin  // Execution result
            if (instr_set == INSTR_CMP) begin
                V = t.V;
                N = t.N;
                Z = t.Z;
                flag_cov.sample();
            end
            expected_out = t.expected_out;
            out_cov.sample();
        end
    endfunction
endclass : uvm_cpu_coverage