    .section    .start
    .global     _start

_start:

# Follow a convention
# x1  = result register 1
# x2  = result register 2
# x3  = extra result for some tests
# x10 = argument 1 register
# x11 = argument 2 register
# x20 = flag register

########################################
# Test 1: ADD
########################################
    li x10, 100         # Load argument 1 (rs1)
    li x11, 200         # Load argument 2 (rs2)
    add x1, x10, x11    # Execute the instruction being tested
    li x20, 1           # Check: x1 == 300

########################################
# Test 2: BEQ (taken, forward)
########################################
    li x2, 100          # Set an initial value of x2
    beq x0, x0, branch1 # This branch should succeed and jump to branch1
    li x2, 123          # This shouldn't execute
branch1:
    li x1, 500          # x1 now contains 500
    li x20, 2           # Check: x1 == 500, x2 == 100

########################################
# Test 3: BEQ (not taken, fall-through)
########################################
    li x1, 0
    li x10, 1
    li x11, 2
    beq x10, x11, beq_not_taken_fail  # Should NOT take
    li x1, 42                         # Should execute
beq_not_taken_fail:
    li x20, 3           # Check: x1 == 42

########################################
# Test 4: BNE (taken, forward)
########################################
    li x1, 0
    li x10, 5
    li x11, 6
    bne x10, x11, bne_taken           # Should take
    li x1, 11                         # Should be skipped
bne_taken:
    li x1, 33
    li x20, 4           # Check: x1 == 33

########################################
# Test 5: BNE (not taken, fall-through)
########################################
    li x1, 0
    li x10, 9
    li x11, 9
    bne x10, x11, bne_not_taken_fail  # Should NOT take
    li x1, 77                         # Should execute
bne_not_taken_fail:
    li x20, 5           # Check: x1 == 77

########################################
# Test 6: BLT (backward loop)
# Loop 5 times:
#   x3 counts iterations
#   x4 = 5
#   x1 accumulates 5 each iteration -> expected x1 = 25
########################################
    li x1, 0
    li x3, 0
    li x4, 5
loop_bl:
    add  x1, x1, x4     # x1 += 5
    addi x3, x3, 1      # x3++
    blt  x3, x4, loop_bl
    li x20, 6           # Check: x1 == 25

########################################
# Test 7: JAL + JALR (forward call/return)
# Use x5 as link register for JAL/JALR.
########################################
    li  x1, 0
    jal x5, func1       # x5 = return address, jump to func1
    li  x20, 7          # After return from func1, Check: x1 == 1234

########################################
# Test 8: J (JAL with rd = x0, forward)
# Unconditional jump that must skip over an instruction.
########################################
    li x1, 0
    jal x0, jump_over   # Jump, but don't write link register
    li x1, 999          # Should be skipped
jump_over:
    li x1, 55
    li x20, 8           # Check: x1 == 55

########################################
# Test 9: Branch using result of previous ALU op
#   add updates x10, branch right after should see new value (no hazard bug).
########################################
    li  x1, 0
    li  x10, 0
    add x10, x10, 1     # x10 = 1
    beq x10, x0, branch_wrong  # Should NOT take
    li  x1, 7           # Should execute if branch sees updated x10
branch_wrong:
    li x20, 9           # Check: x1 == 7

########################################
# Test 10: JAL link register used immediately (BDD-like pattern)
# This mimics the pattern you described that used x1 as a link and then as data:
#   x3 = x10 + x1
#   x3 = x3 - x1   => should recover x10
########################################
    li  x10, 42
    jal x1, jal_link_target
jal_link_target:
    add x3, x10, x1     # x3 = x10 + RA
    sub x3, x3,  x1     # x3 = x10
    li  x20, 10         # Check: x3 == 42

########################################
# Test 11: JALR through address in a register (like indirect calls in bdd)
########################################
    la  x12, jalr_target   # x12 = address of jalr_target
    jalr x5, 0(x12)        # Jump to jalr_target, x5 = return address
    li   x1, 999           # Must be skipped
jalr_target:
    li   x1, 321
    li   x20, 11           # Check: x1 == 321

########################################
# Test 12: Nested branches (taken + not-taken mix)
########################################
    li x1, 0
    li x10, 3
    li x11, 3
    beq x10, x11, nested_true
    j   nested_false
nested_true:
    li   x1, 1
    bne  x10, x11, nested_end   # Not taken
    addi x1, x1, 2              # x1 = 3
    j    nested_end
nested_false:
    li x1, 99
nested_end:
    li x20, 12                  # Check: x1 == 3

########################################
# Test 13: BLT vs BLTU with negative/large values
# This hits the signed/unsigned branch distinction used a lot in array indexing code.
########################################
    li x1, 0
    li x10, -1          # 0xFFFF_FFFF
    li x11, 1

    # Signed comparison: -1 < 1 -> branch taken
    blt  x10, x11, signed_lt
    li   x1, 111        # Should be skipped
signed_lt:
    li   x1, 5          # Expected

    # Unsigned comparison: 0xFFFF_FFFF > 1, so BLTU should NOT be taken
    li   x12, 0
    bltu x10, x11, unsigned_lt
    li   x12, 7         # Should execute
    j    after_unsigned2
unsigned_lt:
    li   x12, 99
after_unsigned2:
    li   x20, 13        # Check: x1 == 5, x12 == 7

########################################
# Done loop so CPU doesn't run off
########################################
done:
    j done

########################################
# Subroutine for Test 7
########################################
func1:
    li x1, 1234         # Value we will check after return
    jalr x0, 0(x5)      # Return using x5 as link register
