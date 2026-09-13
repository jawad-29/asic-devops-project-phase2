`timescale 1ns/1ps

module counter_tb;

    reg clk;
    reg rst;
    wire [3:0] count;

    // Instantiate the counter under test
    counter uut (
        .clk(clk),
        .rst(rst),
        .count(count)
    );

    // Generate a clock: 10 ns period
    always #5 clk = ~clk;

    initial begin
        $display("=================================");
        $display("Starting counter verification...");
        $display("=================================");

        // Initial values
        clk = 1'b0;
        rst = 1'b1;

        // Check asynchronous reset
        #2;

        if (count == 4'b0000)
            $display("PASS: Reset check");
        else
            $display("FAIL: Reset check, count = %d", count);

        // Release reset
        rst = 1'b0;

        // Allow five rising clock edges
        repeat (5) @(posedge clk);
        #1;   

        // Check expected value
        if (count == 4'd5)
            $display("PASS: Counter reached expected value = 5");
        else
            $display("FAIL: Expected 5, got %d", count);

        $display("=================================");

        if (count == 4'd5)
            $display("SIMULATION PASSED");
        else
            $display("SIMULATION FAILED");

        $display("=================================");

        $finish;
    end

endmodule
