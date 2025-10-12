module branch_comp (
    input [31:0] d1,
    input [31:0] d2,
    input un,
    output eq,
    output lt
);
    assign eq = (d1 == d2);
    assign lt = un ? (d1 < d2) : ($signed(d1) < $signed(d2));
endmodule