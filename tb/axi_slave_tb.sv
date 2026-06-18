`timescale 1ns/1ps

module tb;

    logic clk, rst_n;

    // Write Address Channel
    logic        AWVALID;
    logic [31:0] AWADDR;
    logic        AWREADY;

    // Write Data Channel
    logic        WVALID;
    logic [31:0] WDATA;
    logic        WREADY;

    // Write Response Channel
    logic        BREADY;
    logic [1:0]  BRESP;
    logic        BVALID;

    // Read Address Channel
    logic        ARVALID;
    logic [31:0] ARADDR;
    logic        ARREADY;

    // Read Data Channel
    logic        RREADY;
    logic        RVALID;
    logic [1:0]  RRESP;
    logic [31:0] RDATA;

    logic [31:0] read_data;

    //-----------------------------------------
    // DUT
    //-----------------------------------------

    axi_slave dut(
        .clk(clk),
        .rst_n(rst_n),

        .AWVALID(AWVALID),
        .AWADDR(AWADDR),
        .AWREADY(AWREADY),

        .WVALID(WVALID),
        .WDATA(WDATA),
        .WREADY(WREADY),

        .BREADY(BREADY),
        .BRESP(BRESP),
        .BVALID(BVALID),

        .ARVALID(ARVALID),
        .ARADDR(ARADDR),
        .ARREADY(ARREADY),

        .RREADY(RREADY),
        .RVALID(RVALID),
        .RRESP(RRESP),
        .RDATA(RDATA)
    );

   
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    
    // Write Task
   
    task automatic axi_write(
        input logic [31:0] addr,
        input logic [31:0] data
    );

    begin

        @(posedge clk);

        AWADDR  = addr;
        WDATA   = data;
        AWVALID = 1;
        WVALID  = 1;

        @(posedge clk);

        AWVALID = 0;
        WVALID  = 0;

        wait(BVALID);

        BREADY = 1;

        @(posedge clk);

        BREADY = 0;

    end
    endtask
   
    // Read Task
    task automatic axi_read(
        input logic [31:0] addr,
        output logic [31:0] data
    );

    begin

        @(posedge clk);

        ARADDR  = addr;
        ARVALID = 1;

        @(posedge clk);

        ARVALID = 0;

        wait(RVALID);

        RREADY = 1;

        @(posedge clk);

        data = RDATA;

        RREADY = 0;

    end
    endtask

    // Read Checker
    task automatic check_read(
        input logic [31:0] addr,
        input logic [31:0] expected
    );

    begin

        axi_read(addr, read_data);

        if(read_data == expected)
            $display("[%0t] PASS : Address = %h Data = %h",
                     $time, addr, read_data);
        else
            $error("[%0t] FAIL : Address = %h Expected = %h Got = %h",
                   $time, addr, expected, read_data);

    end
    endtask



    initial begin

        rst_n   = 0;

        AWVALID = 0;
        AWADDR  = 0;

        WVALID  = 0;
        WDATA   = 0;

        BREADY  = 0;

        ARVALID = 0;
        ARADDR  = 0;

        RREADY  = 0;

        #20;
        rst_n = 1;

        // Write Tests
        axi_write(32'h00,32'h00000001);
        axi_write(32'h04,32'h12345678);
        axi_write(32'h0C,32'hABCDEF12);

        // Read Tests
       
        check_read(32'h00,32'h00000001);
        check_read(32'h04,32'h12345678);
        check_read(32'h08,32'h00000000);// STATUS register should remain zero
        check_read(32'h0C,32'hABCDEF12);

        // Invalid Address
        check_read(32'h20,32'h00000000);

        
        $display("SUCCESS");
        

        #20;
        $finish;

    end

endmodule