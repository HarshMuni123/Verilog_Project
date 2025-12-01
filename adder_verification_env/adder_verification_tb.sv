`timescale 1ns/1ps

class transaction;
    rand bit [3:0] a;
    rand bit [3:0] b;
    rand bit cin;
    bit [3:0] sum;
    bit cout;

    function transaction copy();
        copy = new();
        copy.a = a;
        copy.b = b;
        copy.cin = cin;
        copy.sum = sum;
        copy.cout = cout;
    endfunction

endclass

class generator;
    transaction trans;
    mailbox #(transaction) gen2drv;

    function new(mailbox #(transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task run();
        for(int i = 0; i < 10; i = i + 1) begin
            trans = new();
          assert(trans.randomize()) else $display("Randzomization failed!");
          $display("[%0t] GEN : a = %04b b = %04b cin = %0b",$time,trans.a,trans.b,trans.cin);
            gen2drv.put(trans);
            #10;
        end
    endtask

endclass

class driver;
    virtual adder_iff adif;
    transaction trans;
    mailbox #(transaction) gen2drv;

    function new(virtual adder_iff adif,mailbox #(transaction) gen2drv);
        this.adif = adif;
        this.gen2drv = gen2drv;
    endfunction

    task run();
        forever begin
           gen2drv.get(trans);
        #0; 
            adif.a = trans.a;
            adif.b = trans.b;
            adif.cin = trans.cin;
          $display("[%0t] DRV : a = %04b b = %04b cin = %0b",$time,adif.a,adif.b,adif.cin); 
          -> adif.driver_done;
            #10;
        end
        
    endtask

endclass

class monitor;

    virtual adder_iff adif;
    mailbox #(transaction) mon2sco;
  	transaction trans;

    function new(virtual adder_iff adif, mailbox #(transaction) mon2sco);
        this.adif    = adif;
        this.mon2sco = mon2sco;
    endfunction
    task run();
        forever begin
            trans = new();
          @adif.driver_done;
          	#0;
            trans.a    = adif.a;
            trans.b    = adif.b;
            trans.cin  = adif.cin;
            trans.sum  = adif.sum;
            trans.cout = adif.cout;

          $display("[%0t] MON : a=%04b b=%04b cin=%0b sum=%04b cout=%0b",
                     $time, trans.a, trans.b, trans.cin, trans.sum, trans.cout);

            mon2sco.put(trans);
        end
    endtask

endclass

class scoreboard;
  virtual adder_iff adif;
  transaction trans;
  mailbox #(transaction) mon2sco;
  
  function new(mailbox #(transaction) mon2sco);
    this.mon2sco = mon2sco;
  endfunction
  
  task run();
    int expected;
    forever begin
      mon2sco.get(trans);
      expected = trans.a + trans.b + trans.cin;
      if({trans.cout,trans.sum} !== expected) begin
         $display("[%0t] SCO: ERROR! a=%04b b=%04b cin=%0b  expected=%05b got={%0b,%0b}",
                         $time, trans.a, trans.b, trans.cin,expected,trans.cout, trans.sum);
         end
         else begin
                $display("[%0t] SCO: PASS  a=%0b b=%0b cin=%0b sum=%0b cout=%0b",
                         $time, trans.a, trans.b, trans.cin,
                         trans.sum, trans.cout);
            end
    end
  endtask
  
endclass


class environment;
    generator gen;
    transaction trans;
  	monitor mon;
  	scoreboard sco;
    driver drv;
    mailbox #(transaction) gen2drv;
  	mailbox #(transaction) mon2sco;
    virtual adder_iff adif;

    function new(virtual adder_iff adif);
        this.adif = adif;
        gen2drv = new();
      	mon2sco = new();
        gen = new(gen2drv);
      sco = new(mon2sco);
      	mon = new(adif,mon2sco);
        drv = new(adif,gen2drv);
    endfunction

    task run();

        fork
            gen.run();
            drv.run();
          	mon.run();
          sco.run();
        join_none
    endtask

endclass


// TESTBENCH CODE HERE
module tb;
    logic a;
    logic b;
    logic cin;
    logic sum;
    logic cout;

    adder_iff adif();
    adder_verify dut(
        .a(adif.a),
        .b(adif.b),
        .cin(adif.cin),
        .sum(adif.sum),
        .cout(adif.cout)
    );
    environment env;


    initial begin
        env = new(adif);
        env.run();
        #200 $finish;
    end

endmodule