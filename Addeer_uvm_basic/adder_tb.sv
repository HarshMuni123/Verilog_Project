`include "uvm_macros.svh"
import uvm_pkg::*;

class drv extends uvm_driver #(uvm_sequence_item);
    `uvm_component_utils(drv)

    virtual adder_if aif;

    function new(string name="drv", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual adder_if)::get(this, "", "aif", aif))
            `uvm_fatal("DRV", "Unable to access interface");
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        for(int i=0; i<10; i++) begin
            aif.a <= $urandom_range(0,15);
            aif.b <= $urandom_range(0,15);
        	#1; // allow DUT to compute

        	`uvm_info("DRV",$sformatf("a=%0d b=%0d s=%0d", aif.a, aif.b, aif.s),UVM_MEDIUM);
        	#9;
    	end
        phase.drop_objection(this);
    endtask
endclass


class agent extends uvm_agent;
    `uvm_component_utils(agent)

    drv d;

    function new(string name="agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        d = drv::type_id::create("drv", this);
    endfunction
endclass

class env extends uvm_env;
    `uvm_component_utils(env)

    agent ag;

    function new(string name="env", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ag = agent::type_id::create("agent", this);
    endfunction
endclass

class test extends uvm_test;
    `uvm_component_utils(test)

    env e;

    function new(string name="test", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        e = env::type_id::create("env", this);
    endfunction
endclass

module tb;

    adder_if aif();

    adder dut (
        .a(aif.a),
        .b(aif.b),
        .s(aif.s)
    );

    initial begin
        uvm_config_db#(virtual adder_if)::set(
            null,
            "uvm_test_top.env.agent.drv",
            "aif",
            aif
        );
        run_test("test");
    end

endmodule
