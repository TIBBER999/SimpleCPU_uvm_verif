import uvm_pkg::*;
import uvm_cpu_pkg::*;

module uvm_top;
    cpu_bfm bfm();

    cpu DUT(
        .clk   (bfm.clk),
        .reset (bfm.reset),
        .s     (bfm.s),
        .load  (bfm.load),
        .in    (bfm.in),
        .out   (bfm.out),
        .N     (bfm.N),
        .V     (bfm.V),
        .Z     (bfm.Z),
        .w     (bfm.w)
    );

    initial begin
        uvm_config_db#(virtual cpu_bfm)::set(null, "*", "bfm", bfm);
        run_test("uvm_cpu_test");
    end

endmodule : uvm_top