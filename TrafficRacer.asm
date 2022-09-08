######################################################################
# CSCB58 Summer 2022 Project
# University of Toronto, Scarborough
#
# Student Name: Alejandro Iglesias Llobet, Student Number: 1006686070, UTorID: iglesi23
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Basic features that were implemented successfully
# - Basic feature a/b/c (choose the ones that apply)
#	Tasks 1-3 Completed Fully!
#	Task 4: a, c
#
# Additional features that were implemented successfully
# - Additional feature a/b/c (choose the ones that apply)
#	N/A (would have been extra lives + invincibility)
#
# Link to the video demo
# - Insert YouTube/MyMedia/other URL here and make sure the video is accessible:
#	VIDEO LINK: https://youtu.be/Z0LU6_LUYhM
#
# Any additional information that the TA needs to know:
# - Write here, if any
#	N/A
#
######################################################################

# Demo for painting
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
.data
displayAddressReal:	.word 0x10008000
displayAddress: .word 0x10008700

TEMP_BACKGROUND: .space 16384	# (256 x 256 / (4 x 4)) x 4 = 16384

LANE_1_FIXED:	.word 12	# lane 1 -  3 (x4) [width]
LANE_2_FIXED:	.word 72	# lane 2 - 18 (x4) [width]
LANE_3_FIXED:	.word 148	# lane 3 - 37 (x4) [width]
LANE_4_FIXED:	.word 208	# lane 4 - 52 (x4) [width]

LANE_1:		.word 6412	# lane 1 -  3 (x4) [width] + 25 (x256) [height]
LANE_2:		.word 6472	# lane 2 - 18 (x4) [width] + 25 (x256) [height]
LANE_3:		.word 6548	# lane 3 - 37 (x4) [width] + 25 (x256) [height]
LANE_4:		.word 6608	# lane 4 - 52 (x4) [width] + 25 (x256) [height]

SPEED_1:	.word 25
SPEED_2:	.word 10
SPEED_3:	.word 5
#MAX_SPEED:	.word 0		# reserved for police cars (i.e. enemies)

ENEMY_CARS:	.word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1	# length is irrelevent.. # of enemies always <= 5 (hopefully!)
CAR_DIRECTION:	.word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1	# dictates direction of car
CAR_LANE:	.word -1,-1,-1,-1,-1,-1,-1,-1,-1,-1	# used for collisions... dictates lane of enemy car

.text
.globl main

# MAIN LOOP

main:
	# Initializing default values
	lw $s0, displayAddress
	li $s1, 3	# number of lives (default is 3)
	# $s2 FORBIDDEN! USED BY FUNCTION FOR CAR COLLISIONS (I.e. car lane setting)
	li $s3, 0	# # of enemy cars in play.. helps with LEN of "ENEMY_CARS" array we want to dynamically use
	li $s4, 4	# enemy car height (0 - 64).. 64 -> RESET!
	li $s5, 4	# responsible for white line movement
	lw $s6, SPEED_1	# Speed Number (default is 1)
	lw $s7, LANE_2	# Lane Number (default is 2)
	
	jal draw_background	# this is without white lines
	jal draw_top_bar
	#j EXIT
	add $t0, $s0, $s7
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	jal draw_main_car
	
	#addi $sp, $sp, -4
	#sw $s4, 0($sp)		# storing height
	
	#jal create_enemy	# responsible for updating ENEMY_CARS, CAR_DIRECTION and $s3
	bne $s3, 0, MAIN_LOOP	# branch if already existing enemies
	jal spawn_enemies	# spawning enemies if no current ones existing! (1-3 for level 1, 2-5 for level 2)
	
	MAIN_LOOP:
	
	li $t9, 0xffff0000
       	lw $t8, 0($t9)
       	bne $t8, 1, keypress_handling_finished
       	
       	# Keypress happened:
       	lw $t0, 4($t9) 			# this assumes $t9 is set to 0xfff0000
	beq $t0, 0x77, respond_to_w 	# ASCII code of 'w' is 0x77 or 119 in decimal
	beq $t0, 0x61, respond_to_a 	# ASCII code of 'a' is 0x61 or 97 in decimal
	beq $t0, 0x73, respond_to_s 	# ASCII code of 's' is 0x73 or 115 in decimal
	beq $t0, 0x64, respond_to_d 	# ASCII code of 'd' is 0x64 or 100 in decimal
	j keypress_handling_finished	# irrelevant keypress
	
	respond_to_w:
		lw $t1, SPEED_1
		lw $t2, SPEED_2
		lw $t3, SPEED_3
		
		bne $s6, $t2, try_speed1_case	# branch if current speed != SPEED_2
		lw $s6, SPEED_3
		j keypress_handling_finished
		
		try_speed1_case:
		bne $s6, $t1, keypress_handling_finished	# branch if current speed != SPEED_1
		lw $s6, SPEED_2					# Notice we don't check for SPEED_3
		j keypress_handling_finished			# case since that's already max speed!
		
	respond_to_a:
		lw $t1, LANE_1
		lw $t2, LANE_2
		lw $t3, LANE_3
		lw $t4, LANE_4
		
		bne $s7, $t1, try_lane2_case		# branch if current lane != LANE_1
		# lose_life <- IMPORTANT FOR LATER!!
		subi $s1, $s1, 1 # $s1 -= 1
		beq $s1, 0, game_over_screen
		# Set car's current position to all gray
		li $s4, 0	# resetting count to 0
		li $s3, 0
		jal draw_background
		
		lw $s7, LANE_2
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car_light_red
		
		li $v0, 32
		li $a0, 100
		syscall
		
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car
		
		
		jal spawn_enemies
		
		j keypress_handling_finished
		
		try_lane2_case:
		bne $s7, $t2, try_lane3_case		# branch if current lane != LANE_2
		lw $t0, displayAddress
		add $t0, $t0, $s7	# $t0 = displayAddress + LANE_2
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_gray_blob	# we draw "gray_blob" at this index (LANE 2)
		
		lw $s7, LANE_1		# $s7 changed to LANE_1
		lw $t0, displayAddress	# $t0 = displayAddress + LANE_1
		add $t0, $t0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car	# we draw "main car" at this index (LANE 1)
		
		try_lane3_case:
		bne $s7, $t3, try_lane4_case		# branch if current lane != LANE_3
		lw $t0, displayAddress
		add $t0, $t0, $s7	# $t0 = displayAddress + LANE_3
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_gray_blob	# we draw "gray_blob" at this index (LANE 3)
		
		lw $s7, LANE_2		# $s7 changed to LANE_2
		lw $t0, displayAddress	# $t0 = displayAddress + LANE_2
		add $t0, $t0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car	# we draw "main car" at this index (LANE 2)
		
		try_lane4_case:
		bne $s7, $t4, keypress_handling_finished # branch if current lane != LANE_4
		
		lw $t0, displayAddress
		add $t0, $t0, $s7	# $t0 = displayAddress + LANE_4
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_gray_blob	# we draw "gray_blob" at this index (LANE 4)
		
		lw $s7, LANE_3		# $s7 changed to LANE_3
		lw $t0, displayAddress	# $t0 = displayAddress + LANE_3
		add $t0, $t0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car	# we draw "main car" at this index (LANE 3)
		
		j keypress_handling_finished
		
	respond_to_s:
		lw $t1, SPEED_1
		lw $t2, SPEED_2
		lw $t3, SPEED_3
		
		bne $s6, $t2, try_speed3_case	# branch if current speed != SPEED_2
		lw $s6, SPEED_1
		j keypress_handling_finished
		
		try_speed3_case:
		bne $s6, $t3, keypress_handling_finished	# branch if current speed != SPEED_3
		lw $s6, SPEED_2				# Notice we don't check for SPEED_1
		j keypress_handling_finished			# case since that's already min speed!
	
	respond_to_d:
		lw $t1, LANE_1
		lw $t2, LANE_2
		lw $t3, LANE_3
		lw $t4, LANE_4
		
		bne $s7, $t4, try_lane3_case_d		# branch if current lane != LANE_4
		# lose_life <- IMPORTANT FOR LATER!!
		subi $s1, $s1, 1 # $s1 -= 1
		beq $s1, 0, game_over_screen
		# Set car's current position to all gray
		li $s4, 0	# resetting count to 0
		li $s3, 0
		jal draw_background
		
		lw $s7, LANE_2
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car_light_red
		
		li $v0, 32
		li $a0, 100
		syscall
		
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car
		
		
		jal spawn_enemies
		
		j keypress_handling_finished
		
		try_lane3_case_d:
		bne $s7, $t3, try_lane2_case_d		# branch if current lane != LANE_3
		lw $t0, displayAddress
		add $t0, $t0, $s7	# $t0 = displayAddress + LANE_3
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_gray_blob	# we draw "gray_blob" at this index (LANE 3)
		
		lw $s7, LANE_4		# $s7 changed to LANE_4
		lw $t0, displayAddress	# $t0 = displayAddress + LANE_4
		add $t0, $t0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car	# we draw "main car" at this index (LANE 4)
		
		try_lane2_case_d:
		bne $s7, $t2, try_lane1_case_d		# branch if current lane != LANE_2
		lw $t0, displayAddress
		add $t0, $t0, $s7	# $t0 = displayAddress + LANE_2
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_gray_blob	# we draw "gray_blob" at this index (LANE 2)
		
		lw $s7, LANE_3		# $s7 changed to LANE_3
		lw $t0, displayAddress	# $t0 = displayAddress + LANE_3
		add $t0, $t0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car	# we draw "main car" at this index (LANE 3)
		
		try_lane1_case_d:
		bne $s7, $t1, keypress_handling_finished # branch if current lane != LANE_1
		
		lw $t0, displayAddress
		add $t0, $t0, $s7	# $t0 = displayAddress + LANE_1
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_gray_blob	# we draw "gray_blob" at this index (LANE 1)
		
		lw $s7, LANE_2		# $s7 changed to LANE_2
		lw $t0, displayAddress	# $t0 = displayAddress + LANE_2
		add $t0, $t0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car	# we draw "main car" at this index (LANE 2)
		
		j keypress_handling_finished
       	
       	
	keypress_handling_finished:
	
	# CHECK FOR COLLISION HERE!
	jal check_collision

	lw $t4, 0($sp)		# retrieving return value from call to 'check_collision'
	addi $sp, $sp, 4
	
	bne $t4, 1, no_collision_detected
	# Collision Detected!
		# lose_life <- IMPORTANT FOR LATER!!
		subi $s1, $s1, 1 # $s1 -= 1
		beq $s1, 0, game_over_screen
		# Set car's current position to all gray
		li $s4, 0	# resetting count to 0
		li $s3, 0
		jal draw_background
		
		lw $s7, LANE_2
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car_light_red
		
		li $v0, 32
		li $a0, 100
		syscall
		
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car
		
		
		jal spawn_enemies
	
	
	no_collision_detected:
	#jal draw_background	# this is without white lines
	
	#add $t0, $s0, $s7
	#addi $sp, $sp, -4
	#sw $t0, 0($sp)
	#jal draw_main_car
	
#	jal draw_temp_background
	
	jal update_enemy_positions
	jal draw_top_bar
	
	addi $s4, $s4, 1	# indicate update_enemy_position call
	blt $s4, 77, proceed_as_normal	# 81 - 4 is the magic number for some reason haha! # change to 80 to view rear of police cars :]
	# This means that each car has finished (64 is upper bound... might have to wait a little between rounds)
	li $s4, 0	# resetting count to 0
	li $s3, 0	# deleting all instances of moving cars (since while 0<0 always false)
	jal spawn_enemies
	
	proceed_as_normal:
	#jal draw_police_car_up
	# All this code below within the MAIN_LOOP is responsible for screen movement.
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra
	
	addi $sp, $sp, -4
	sw $s5, 0($sp)
	jal draw_white_lines
	# jal update_enemy_position # maybe have register $s3 as array of enemy top-left positions
	# if 64th iteration of update_enemy_position, re-call create random set of enemies
	
	lw $ra, 0($s0)		# loading old $ra
	addi $sp, $sp, 4
	
	# waiting (sleep method call)
	li $v0, 32
	move $a0, $s6
	syscall
	
	addi $s5, $s5, -1
	bne $s5, -1, MAIN_LOOP
	li $s5, 4
	
	j MAIN_LOOP

game_over_screen:
	jal draw_game_over
	
	wait_for_user:
	li $t9, 0xffff0000
       	lw $t8, 0($t9)
       	beq $t8, 1, respond_to_key_press
       	j wait_for_user
       	
       	respond_to_key_press:
       	# Keypress happened:
       	lw $t0, 4($t9) 			# this assumes $t9 is set to 0xfff0000
	beq $t0, 0x72, respond_to_r 	# ASCII code of 'r' is 0x72 or 114 in decimal
	beq $t0, 0x71, respond_to_q 	# ASCII code of 'q' is 0x71 or 113 in decimal
	j wait_for_user			# irrelevant key press
	
	respond_to_r:
	j main
	
	respond_to_q:
	j EXIT
	

EXIT:
       li $v0, 10 # terminate the program
       syscall

draw_police_car_up:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	#lw $t0, displayAddress
	
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x808080	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x808080	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0xfcde32	# $t2 stores the green colour code
	li $t3, 0xfcde32	# $t3 stores the blue colour code
	li $t4, 0x00bae8	# $t3 stores the blue colour code
	li $t5, 0x00bae8	# $t3 stores the blue colour code
	li $t6, 0x00bae8	# $t3 stores the blue colour code
	li $t7, 0xfcde32	# $t3 stores the blue colour code
	li $t8, 0xfcde32	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x56c8ea	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x56c8ea	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x56c8ea	# $t2 stores the green colour code
	li $t3, 0x00bae8	# $t3 stores the blue colour code
	li $t4, 0x00bae8	# $t3 stores the blue colour code
	li $t5, 0x00bae8	# $t3 stores the blue colour code
	li $t6, 0x00bae8	# $t3 stores the blue colour code
	li $t7, 0x00bae8	# $t3 stores the blue colour code
	li $t8, 0x56c8ea	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x56c8ea	# $t2 stores the green colour code
	li $t3, 0x404040	# $t3 stores the blue colour code
	li $t4, 0x4a4a4c	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x404040	# $t3 stores the blue colour code
	li $t7, 0x4a4a4c	# $t3 stores the blue colour code
	li $t8, 0x56c8ea	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x56c8ea	# $t1 stores the red colour code
	li $t2, 0x4a4a4c	# $t2 stores the green colour code
	li $t3, 0x4a4a4c	# $t3 stores the blue colour code
	li $t4, 0x404040	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x4a4a4c	# $t3 stores the blue colour code
	li $t7, 0x404040	# $t3 stores the blue colour code
	li $t8, 0x4a4a4c	# $t3 stores the blue colour code
	li $t9, 0x56c8ea	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x404040	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x4a4a4c	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x404040	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x404040	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x404040	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x404040	# $t3 stores the blue colour code
	li $t5, 0x404040	# $t3 stores the blue colour code
	li $t6, 0x4a4a4c	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x404040	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x404040	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x404040	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x4a4a4c	# $t3 stores the blue colour code
	li $t4, 0x404040	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x404040	# $t3 stores the blue colour code
	li $t7, 0x4a4a4c	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0xec1c24	# $t2 stores the green colour code
	li $t3, 0xec1c24	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0xec1c24	# $t3 stores the blue colour code
	li $t8, 0xec1c24	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	jr $ra

draw_police_car_down:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	#lw $t0, displayAddress
	
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0xec1c24	# $t2 stores the green colour code
	li $t3, 0xec1c24	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0xec1c24	# $t3 stores the blue colour code
	li $t8, 0xec1c24	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x4a4a4c	# $t3 stores the blue colour code
	li $t4, 0x404040	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x404040	# $t3 stores the blue colour code
	li $t7, 0x4a4a4c	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x404040	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x404040	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x404040	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x404040	# $t3 stores the blue colour code
	li $t5, 0x404040	# $t3 stores the blue colour code
	li $t6, 0x4a4a4c	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x404040	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x404040	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x4a4a4c	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x404040	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x404040	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x00bae8	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x00bae8	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x56c8ea	# $t1 stores the red colour code
	li $t2, 0x4a4a4c	# $t2 stores the green colour code
	li $t3, 0x4a4a4c	# $t3 stores the blue colour code
	li $t4, 0x404040	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x4a4a4c	# $t3 stores the blue colour code
	li $t7, 0x404040	# $t3 stores the blue colour code
	li $t8, 0x4a4a4c	# $t3 stores the blue colour code
	li $t9, 0x56c8ea	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x56c8ea	# $t2 stores the green colour code
	li $t3, 0x404040	# $t3 stores the blue colour code
	li $t4, 0x4a4a4c	# $t3 stores the blue colour code
	li $t5, 0x4a4a4c	# $t3 stores the blue colour code
	li $t6, 0x404040	# $t3 stores the blue colour code
	li $t7, 0x4a4a4c	# $t3 stores the blue colour code
	li $t8, 0x56c8ea	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x56c8ea	# $t2 stores the green colour code
	li $t3, 0x00bae8	# $t3 stores the blue colour code
	li $t4, 0x00bae8	# $t3 stores the blue colour code
	li $t5, 0x00bae8	# $t3 stores the blue colour code
	li $t6, 0x00bae8	# $t3 stores the blue colour code
	li $t7, 0x00bae8	# $t3 stores the blue colour code
	li $t8, 0x56c8ea	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x231f20	# $t1 stores the red colour code
	li $t2, 0x56c8ea	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x56c8ea	# $t3 stores the blue colour code
	li $t9, 0x231f20	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0xfcde32	# $t2 stores the green colour code
	li $t3, 0xfcde32	# $t3 stores the blue colour code
	li $t4, 0x00bae8	# $t3 stores the blue colour code
	li $t5, 0x00bae8	# $t3 stores the blue colour code
	li $t6, 0x00bae8	# $t3 stores the blue colour code
	li $t7, 0xfcde32	# $t3 stores the blue colour code
	li $t8, 0xfcde32	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	addi $t0, $t0, 256
	li $t1, 0x808080	# $t1 stores the red colour code
	li $t2, 0x808080	# $t2 stores the green colour code
	li $t3, 0x56c8ea	# $t3 stores the blue colour code
	li $t4, 0x56c8ea	# $t3 stores the blue colour code
	li $t5, 0x56c8ea	# $t3 stores the blue colour code
	li $t6, 0x56c8ea	# $t3 stores the blue colour code
	li $t7, 0x56c8ea	# $t3 stores the blue colour code
	li $t8, 0x808080	# $t3 stores the blue colour code
	li $t9, 0x808080	# $t3 stores the blue colour code
	sw $t1, 0($t0)		# paint the first (top-left) unit red
	sw $t2, 4($t0)		
	sw $t3, 8($t0)		
	sw $t4, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t7, 24($t0)		
	sw $t8, 28($t0)		
	sw $t9, 32($t0)
	
	jr $ra

# void draw_at(char *arr, int width, int height, int index)
draw_at:
	# C script:
	#
	# int i = 0;
	# while (i < height) {
	#	int j = 0;
	#	while (j < width) {
	#		*(displayAddress + index + i*256 + j) = *(arr + i*(width + 1) + j);
	#		j++;
	#	}
	#	i++;
	# }
	# return;

# draw_road_row_with_white(int height)
draw_road_row_without_white:
	lw $t0, 4($sp)		# $t0 = index
	lw $t5, 0($sp)		# white (2/3) or gray (1/3)
	addi $sp, $sp, 8	# adjust stack pointer
	li $t6, 0x7EC850	# green
	li $t7, 0xfff000	# yellow
	li $t8, 0xffffff	# white
	li $t9, 0x808080	# gray
	
	# Draw 1px of green
	sw $t6, 0($t0)
	addi $t0, $t0, 4
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of white (3/5) or gray (2/5)
	sw $t5, 0($t0)
	sw $t5, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of yellow
	sw $t7, 0($t0)
	sw $t7, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 2px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 2px of yellow
	sw $t7, 0($t0)
	sw $t7, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of white (3/5) or gray (2/5)
	sw $t5, 0($t0)
	sw $t5, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 1px of green
	sw $t6, 0($t0)
	addi $t0, $t0, 4
	
	jr $ra

draw_main_car:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	#move $t0, $s7
	
	li $t3, 0xee383f	# light red
	li $t4, 0xc92e34	# dark red
	li $t5, 0x323031	# light black
	li $t6, 0x231f20	# dark black
	li $t7, 0xfcde32	# yellow
	li $t8, 0xffffff	# white
	li $t9, 0x808080	# gray
	
	# Front of car (row 1/14)
	sw $t9, 0($t0)
	sw $t9, 4($t0)		
	sw $t4, 8($t0)		
	sw $t4, 12($t0)		
	sw $t4, 16($t0)		
	sw $t4, 20($t0)
	sw $t4, 24($t0)		
	sw $t9, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 2/14
	sw $t9, 0($t0)
	sw $t7, 4($t0)		
	sw $t7, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t7, 24($t0)		
	sw $t7, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 3/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 4/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 5/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 6/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t6, 8($t0)		
	sw $t5, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t5, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 7/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t5, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t5, 20($t0)
	sw $t6, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 8/14
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 9/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 10/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 11/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 12/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 13/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Back of car (row 14/14)
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	
	jr $ra

draw_main_car_light_red:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	#move $t0, $s7
	
	li $t3, 0xFF7F7F	# light red
	li $t4, 0xFF7F7F	# dark red
	li $t5, 0xFF7F7F	# light black
	li $t6, 0xFF7F7F	# dark black
	li $t7, 0xFF7F7F	# yellow
	li $t8, 0xFF7F7F	# white
	li $t9, 0x808080	# gray
	
	# Front of car (row 1/14)
	sw $t9, 0($t0)
	sw $t9, 4($t0)		
	sw $t4, 8($t0)		
	sw $t4, 12($t0)		
	sw $t4, 16($t0)		
	sw $t4, 20($t0)
	sw $t4, 24($t0)		
	sw $t9, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 2/14
	sw $t9, 0($t0)
	sw $t7, 4($t0)		
	sw $t7, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t7, 24($t0)		
	sw $t7, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 3/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 4/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 5/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 6/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t6, 8($t0)		
	sw $t5, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t5, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 7/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t5, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t5, 20($t0)
	sw $t6, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 8/14
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 9/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 10/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 11/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 12/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 13/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Back of car (row 14/14)
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	
	jr $ra

draw_main_car_dark_red:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	#move $t0, $s7
	
	li $t3, 0xc92e34	# light red
	li $t4, 0xc92e34	# dark red
	li $t5, 0xc92e34	# light black
	li $t6, 0xc92e34	# dark black
	li $t7, 0xc92e34	# yellow
	li $t8, 0xc92e34	# white
	li $t9, 0x808080	# gray
	
	# Front of car (row 1/14)
	sw $t9, 0($t0)
	sw $t9, 4($t0)		
	sw $t4, 8($t0)		
	sw $t4, 12($t0)		
	sw $t4, 16($t0)		
	sw $t4, 20($t0)
	sw $t4, 24($t0)		
	sw $t9, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 2/14
	sw $t9, 0($t0)
	sw $t7, 4($t0)		
	sw $t7, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t7, 24($t0)		
	sw $t7, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 3/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 4/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 5/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 6/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t6, 8($t0)		
	sw $t5, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t5, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 7/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t5, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t5, 20($t0)
	sw $t6, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 8/14
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 9/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 10/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 11/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 12/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 13/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Back of car (row 14/14)
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	
	jr $ra
			
draw_gray_blob:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	
	li $t3, 0x808080	# light red 	- changed to gray
	li $t4, 0x808080	# dark red 	- changed to gray
	li $t5, 0x808080	# light black 	- changed to gray
	li $t6, 0x808080	# dark black 	- changed to gray
	li $t7, 0x808080	# yellow 	- changed to gray
	li $t8, 0x808080	# white 	- changed to gray
	li $t9, 0x808080	# gray 		- changed to gray
	
	# Front of car (row 1/14)
	sw $t9, 0($t0)
	sw $t9, 4($t0)		
	sw $t4, 8($t0)		
	sw $t4, 12($t0)		
	sw $t4, 16($t0)		
	sw $t4, 20($t0)
	sw $t4, 24($t0)		
	sw $t9, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 2/14
	sw $t9, 0($t0)
	sw $t7, 4($t0)		
	sw $t7, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t7, 24($t0)		
	sw $t7, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 3/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 4/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 5/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t5, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 6/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t6, 8($t0)		
	sw $t5, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t5, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 7/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t5, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t5, 20($t0)
	sw $t6, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 8/14
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 9/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 10/14
	sw $t9, 0($t0)
	sw $t6, 4($t0)		
	sw $t3, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t3, 24($t0)		
	sw $t6, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	# Row 11/14
	sw $t6, 0($t0)
	sw $t4, 4($t0)		
	sw $t3, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t3, 24($t0)		
	sw $t4, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 12/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Row 13/14
	sw $t6, 0($t0)
	sw $t3, 4($t0)		
	sw $t6, 8($t0)		
	sw $t6, 12($t0)		
	sw $t6, 16($t0)		
	sw $t6, 20($t0)
	sw $t6, 24($t0)		
	sw $t3, 28($t0)		
	sw $t6, 32($t0)
	addi $t0, $t0, 256
	
	# Back of car (row 14/14)
	sw $t9, 0($t0)
	sw $t4, 4($t0)		
	sw $t4, 8($t0)		
	sw $t8, 12($t0)		
	sw $t8, 16($t0)		
	sw $t8, 20($t0)
	sw $t4, 24($t0)		
	sw $t4, 28($t0)		
	sw $t9, 32($t0)
	addi $t0, $t0, 256
	
	
	jr $ra

draw_background:
		#li $s1, 0
		#li $s2, 64
		#li $s3, 0
		li $t1, 0
		li $t2, 57
		li $t3, 0
	draw_background_loop:
		bge $t1, $t2, end_draw_background
		lw $t0, displayAddress
		mul $t4, $t3, 256
		add $t0, $t0, $t4	# $t0 = displayAddress + i*256
		
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)		# storing old $ra
		
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_road_row
		
		lw $ra, 0($sp)		# loading old $ra
		addi $sp, $sp, 4
		
		# waiting 10ms
		#li $v0, 32
		#li $a0, 10
		#syscall
	
		addi $t3, $t3, 1
		addi $t1, $t1, 1
		
		j draw_background_loop
	
	end_draw_background:
		jr $ra




# draw_road_row_with_white(int height)
draw_road_row:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	li $t6, 0x7EC850	# green
	li $t7, 0xfff000	# yellow
	li $t8, 0xffffff	# white
	li $t9, 0x808080	# gray
	
	# Draw 1px of green
	sw $t6, 0($t0)
	addi $t0, $t0, 4
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of white (3/5) or gray (2/5) - changed to gray
	sw $t9, 0($t0) # was $t8
	sw $t9, 4($t0) # was $t8
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of yellow
	sw $t7, 0($t0)
	sw $t7, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 2px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 2px of yellow
	sw $t7, 0($t0)
	sw $t7, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of white (3/5) or gray (2/5) - changed to gray
	sw $t9, 0($t0) # was $t8
	sw $t9, 4($t0) # was $t8
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 1px of beige
	sw $t6, 0($t0)
	addi $t0, $t0, 4
	
	jr $ra

draw_road_row_without_white2:
	lw $t0, 0($sp)		# $t0 = index
	addi $sp, $sp, 4	# adjust stack pointer
	li $t6, 0x7EC850	# green
	li $t7, 0xfff000	# yellow
	li $t8, 0xffffff	# white
	li $t9, 0x808080	# gray
	
	# Draw 1px of green
	sw $t6, 0($t0)
	addi $t0, $t0, 4
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of white (3/5) or gray (2/5) - changed to gray
	#sw $t9, 0($t0) # was $t8
	#sw $t9, 4($t0) # was $t8
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of yellow
	sw $t7, 0($t0)
	sw $t7, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 2px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 2px of yellow
	sw $t7, 0($t0)
	sw $t7, 4($t0)
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 2px of white (3/5) or gray (2/5) - changed to gray
	#sw $t9, 0($t0) # was $t8
	#sw $t9, 4($t0) # was $t8
	addi $t0, $t0, 8
	
	# Draw 13px of gray
	sw $t9, 0($t0)
	sw $t9, 4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	addi $t0, $t0, 52
	
	# Draw 1px of green
	sw $t6, 0($t0)
	addi $t0, $t0, 4
	
	jr $ra
	
draw_white_lines:
		#li $s1, 0
		#li $s2, 64
		#li $s3, 0
		li $t1, 0
		li $t2, 64
		li $t3, 0
		
		
		lw $t9, 0($sp)	# 0-4 DETERMINES "ILLUSION" OF LINE MOVEMENT.. make parameter input
		addi $sp, $sp, 4
	draw_white_lines_loop:
		bge $t1, $t2, end_draw_white_lines_loop
		lw $t0, displayAddress
		mul $t4, $t3, 256
		add $t0, $t0, $t4	# $t0 = displayAddress + i*256
		
		li $t8, 0xffffff
		ble $t9, 2, dont_make_gray
		li $t8, 0x808080	# making $t8 gray since $t8 > 2 (white = 0,1,2 && gray = 3,4)
		bne $t9, 4, dont_make_gray
		li $t9, -1		# making $t9 -1 since we will call $t9 += 1 and have it at 0, as wanted
		
	dont_make_gray:
		sw $t8, 56($t0)
		sw $t8, 60($t0)
		sw $t8, 192($t0)
		sw $t8, 196($t0)
		
		# waiting 10ms
		#li $v0, 32
		#li $a0, 10
		#syscall
	
		addi $t3, $t3, 1
		addi $t1, $t1, 1
		addi $t9, $t9, 1
		
		j draw_white_lines_loop
	
	end_draw_white_lines_loop:
		jr $ra
	
create_enemy:
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall
	
	move $t0, $a0	# Lane random number (0, 1, 2 or 3)
	
	
	lw $t1, displayAddress
	
	# Case 1: $t0 = 0 => Lane 1
	bne $t0, 0, case_two	# branch if $t0 != 0 (i.e. not LANE_1!)
	lw $t0, LANE_1_FIXED
	add $t0, $t0, $t1 	# $t0 = displayAddress + LANE_1_FIXED
	
	lw $s2, LANE_1		# Will be set as CAR_LANE at end of function call!
	j create_enemy_down
	
	
	case_two:
	# Case 2: $t0 = 1 => Lane 2
	bne $t0, 1, case_three	# branch if $t0 != 0 (i.e. not LANE_2!)
	lw $t0, LANE_2_FIXED
	add $t0, $t0, $t1 	# $t0 = displayAddress + LANE_2_FIXED
	
	lw $s2, LANE_2		# Will be set as CAR_LANE at end of function call!
	j create_enemy_down
	
	
	case_three:
	# Case 3: $t0 = 2 => Lane 3
	bne $t0, 2, case_four	# branch if $t0 != 0 (i.e. not LANE_3!)
	lw $t0, LANE_3_FIXED
	add $t0, $t0, $t1 	# $t0 = displayAddress + LANE_3_FIXED
	
	lw $s2, LANE_3		# Will be set as CAR_LANE at end of function call!
	j create_enemy_up
	
	
	case_four:
	# Case 4: $t0 = 3 => Lane 4
	# guaranteed to be case 4... no branching needed
	lw $t0, LANE_4_FIXED
	add $t0, $t0, $t1 	# $t0 = displayAddress + LANE_4_FIXED
	
	lw $s2, LANE_4		# Will be set as CAR_LANE at end of function call!
	j create_enemy_up
	
	create_enemy_down:
		addi $sp, $sp, -4
		sw $ra, 0($sp)		# store old $ra
		
		subi $t0, $t0, 3328	# make it start from very bottom.. maybe subtract another 256?
		# mul height * 256 and add this to $t0
		#mul $t9, $s4, 256
		#add $t0, $t0, $t9
		
		addi $sp, $sp, -4	# this $t0 is for returning purposes
		sw $t0, 0($sp)
		
		addi $sp, $sp, -4	# this $t0 is for draw_police_car_up function
		sw $t0, 0($sp)
		jal draw_police_car_down
		
		lw $t0, 0($sp)		# this is $t0 from before for returning..
		lw $ra, 4($sp)		# load old $ra
		addi $sp, $sp, 8
		
		li $t5, 0		# useful for CAR_DIRECTION later..
		
		j end_create_enemy
		
	create_enemy_up:
		addi $sp, $sp, -4
		sw $ra, 0($sp)		# store old $ra
		
		addi $t0, $t0, 12800
		addi $t0, $t0, 3328	# make it start from very bottom.. maybe add another 256?
		# mul height * 256 and subtract this from $t0
		#mul $t9, $s4, 256
		#sub $t0, $t0, $t9
		
		addi $sp, $sp, -4	# this $t0 is for returning purposes
		sw $t0, 0($sp)
		
		addi $sp, $sp, -4	# this $t0 is for draw_police_car_up function
		sw $t0, 0($sp)
		jal draw_police_car_up
		
		lw $t0, 0($sp)		# this is $t0 from before for returning..
		lw $ra, 4($sp)		# load old $ra
		addi $sp, $sp, 8
		
		li $t5, 1		# useful for CAR_DIRECTION later..
		
		j end_create_enemy
	
	end_create_enemy:
		#addi $sp, $sp, -4
		#sw $t0, 0($sp)
		
		la $t9, ENEMY_CARS
		mul $t8, $s3, 4
		add $t9, $t9, $t8	# $t9 = addr(ENEMY_CARS) + $s3
		sw $t0, 0($t9)		# *(ENEMY_CARS + $s3) = $t0 = location of car (index)
		
		la $t9, CAR_DIRECTION
		mul $t8, $s3, 4
		add $t9, $t9, $t8	# $t9 = addr(CAR_DIRECTION) + $s3
		sw $t5, 0($t9)		# set to be 0 in "car_down" case and 1 in "car_up" case before jumping
		
		la $t9, CAR_LANE
		mul $t8, $s3, 4
		add $t9, $t9, $t8	# $t9 = addr(CAR_LANE) + $s3
		sw $s2, 0($t9)		# set to be 0 in "car_down" case and 1 in "car_up" case before jumping	
		
		
		addi $s3, $s3, 1	# augment $s3 by 1 to indicate +1 enemy cars
		
		jr $ra

update_enemy_positions:
	li $t0, 0	# $t0 = 0 = loop starting index (looping over array of existing enemy cars.. namely $s3 total cars)
	
	update_enemy_positions_loop:
	beq $t0, $s3, end_update_enemy_positions_loop	# branch if $t0 = $s3 (i.e. we've already looped through each car)
	
	# LOGIC BEHIND UPDATING A CAR'S POSITION!
	la $t9, ENEMY_CARS
	mul $t8, $t0, 4
	add $t9, $t9, $t8	# $t9 = addr(ENEMY_CARS) + ($t0 * 4) = address of $t0'th car in ENEMY_CARS (for position index)
	lw $t1, 0($t9)		# $t1 = *(addr(ENEMY_CARS) + ($t0 * 4)) = position index of $t0'th enemy car
	
	la $t8, CAR_DIRECTION
	mul $t7, $t0, 4
	add $t8, $t8, $t7	# $t8 = addr(CAR_DIRECTION) + ($t0 * 4) = address of $t0'th car in CAR_DIRECTION (for direction value)
	lw $t2, 0($t8)		# $t2 = *(addr(CAR_DIRECTION) + ($t0 * 4)) = direction value of $t0'th enemy car
	
	# Case 1: $t2 = 0 -> Car is moving DOWN (i.e. in Lane 1 or 2)
	bne $t2, 0, car_moving_up_case
	
	# Recall: $t9 = address of $t0'th car index position, $t1 = value at that address
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra value
	addi $sp, $sp, -4
	sw $t9, 0($sp)		# storing $t9 to use after call to 'draw_gray_blob' function
	addi $sp, $sp, -4
	sw $t1, 0($sp)		# storing $t1 to use after call to 'draw_gray_blob' function
	addi $sp, $sp, -4
	sw $t0, 0($sp)		# storing $t0 to use after call to 'draw_gray_blob' function -- necessary for looping
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal draw_gray_blob	# old car placement replaced with gray fill
	
	lw $t0, 0($sp)		# restoring old value of $t0
	lw $t1, 4($sp)		# restoring old value of $t1
	lw $t9, 8($sp)		# restoring old value of $t9
	lw $ra, 12($sp)		# restoring old $ra value
	addi $sp, $sp, 16
	
	addi $t1, $t1, 256	# updating index to point to next line in Bitmap Display - Adding 256 pixels (to go down!)
	sw $t1, 0($t9)		# updating ENEMY_CARS array of positions to reflect this new car position
	
	# All that's left now is to actually draw the car again at this position!
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra value
	addi $sp, $sp, -4
	sw $t0, 0($sp)		# storing $t0 to use after call to 'draw_police_car_down' function -- necessary for looping
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)		# drawing car at this *new* $t1 position index (i.e. the next line)
	jal draw_police_car_down
	
	lw $t0, 0($sp)		# restoring old value of $t0
	lw $ra, 4($sp)		# restoring old $ra value
	addi $sp, $sp, 8
	
	j resume_enemy_positions_loop
	
	# Case 2: $t2 = 1 -> Car is moving UP (i.e. in Lane 3 or 4)
	car_moving_up_case:
	
	# Recall: $t9 = address of $t0'th car index position, $t1 = value at that address
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra value
	addi $sp, $sp, -4
	sw $t9, 0($sp)		# storing $t9 to use after call to 'draw_gray_blob' function
	addi $sp, $sp, -4
	sw $t1, 0($sp)		# storing $t1 to use after call to 'draw_gray_blob' function
	addi $sp, $sp, -4
	sw $t0, 0($sp)		# storing $t0 to use after call to 'draw_gray_blob' function -- necessary for looping
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal draw_gray_blob	# old car placement replaced with gray fill
	
	lw $t0, 0($sp)		# restoring old value of $t0
	lw $t1, 4($sp)		# restoring old value of $t1
	lw $t9, 8($sp)		# restoring old value of $t9
	lw $ra, 12($sp)		# restoring old $ra value
	addi $sp, $sp, 16
	
	subi $t1, $t1, 256	# updating index to point to next line in Bitmap Display - Subtracting 256 pixels (to go up!)
	sw $t1, 0($t9)		# updating ENEMY_CARS array of positions to reflect this new car position
	
	# All that's left now is to actually draw the car again at this position!
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra value
	addi $sp, $sp, -4
	sw $t0, 0($sp)		# storing $t0 to use after call to 'draw_police_car_up' function -- necessary for looping
	
	addi $sp, $sp, -4
	sw $t1, 0($sp)		# drawing car at this *new* $t1 position index (i.e. the next line)
	jal draw_police_car_up
	
	lw $t0, 0($sp)		# restoring old value of $t0
	lw $ra, 4($sp)		# restoring old $ra value
	addi $sp, $sp, 8
	
	#j resume_enemy_positions_loop # - redundant...
	
	
	resume_enemy_positions_loop:
	
	addi $t0, $t0, 1
	j update_enemy_positions_loop
	
	end_update_enemy_positions_loop:
		jr $ra
		
		
############
legacy_code:
		li $t8, 0xffffff
		ble $t6, 3, draw_background_SKIP_MAKE_GRAY
		li $t8, 0x808080
		bne $t6, 5, draw_background_SKIP_MAKE_GRAY
		addi $t6, $zero, -1

	draw_background_SKIP_MAKE_GRAY:
		addi $sp, $sp -4
		sw $ra, 0($sp)
		
		addi $sp, $sp, -4
		#sw 
		
		addi $sp, $sp, -4
		sw $t8, 0($sp)
		jal draw_road_row
	
		li $v0, 32
		li $a0, 10
		syscall

fill_temp_background:
		li $t1, 0
		li $t2, 64
		li $t3, 0
	fill_temp_background_loop:
		bge $t1, $t2, end_fill_temp_background
		la $t0, TEMP_BACKGROUND
		mul $t4, $t3, 256
		add $t0, $t0, $t4	# $t0 = addr(TEMP_BACKGROUND) + i*256
		
		
		addi $sp, $sp, -4
		sw $ra, 0($sp)		# storing old $ra
		
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_road_row_without_white2
		
		lw $ra, 0($sp)		# loading old $ra
		addi $sp, $sp, 4
		
		# waiting 10ms
		#li $v0, 32
		#li $a0, 10
		#syscall
	
		addi $t3, $t3, 1
		addi $t1, $t1, 1
		
		j fill_temp_background_loop
	
	end_fill_temp_background:
		# Now we must also fill in the car!
		add $t0, $s0, $s7
		addi $sp, $sp, -4
		sw $t0, 0($sp)
		jal draw_main_car
		
		jr $ra

draw_temp_background:
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra value
	
	jal fill_temp_background
	
	lw $ra, 0($sp)		# restoring old $ra value
	addi $sp, $sp, 4
	
	
	
	li $t8, 0		# index i
	li $t9, 65536		# 16384 x 4 = 65536
	
	draw_temp_background_loop:
	beq $t8, $t9, end_draw_temp_background		# branch after 16384 iterations
	
	### LOOP LOGIC ###
	
	lw $t0, displayAddress
	add $t0, $t0, $t8	# $t0 = displayAddress + i
	
	la $t1, TEMP_BACKGROUND
	add $t1, $t1, $t8	# $t1 = address(TEMP_BACKGROUND) + i
	lw $t2, 0($t1)		# $t2 = TEMP_BACKGROUND[i]
	
	sw $t2, 0($t0)		# *(displayAddress + i) = TEMP_BACKGROUND[i]
	
	
	
	### LOOP LOGIC ###
	
	addi $t8, $t8, 4
	j draw_temp_background_loop
	
	end_draw_temp_background:
		jr $ra	

spawn_enemies:
	#lw $t0, 0($sp)		# to determine level (1 or 2). This will decide if to spawn 1-3 or 2-5 enemy cars!
	#addi $sp, $sp, 4	# (ie. $t0 = 3 or 5 and set $a1 to that value before syscall)
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	
	move $t9, $a0	# Enemies (to spawn) random number (0, 1, or 2). 3 & 4 also exist if level = 2
	
	li $t8, -1
	
	spawn_car_loop:
	beq $t8, $t9, stop_spawning
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)		# storing old $ra value
	addi $sp, $sp, -4
	sw $t9, 0($sp)		# storing old value of $t9
	addi $sp, $sp, -4
	sw $t8, 0($sp)		# storing old value of $t8
	
	jal create_enemy	# spawning enemy car
	
	lw $t8, 0($sp)		# restoring old $t8 value
	lw $t9, 4($sp)		# restoring old $t9 value
	lw $ra, 8($sp)		# restoring old $ra value
	addi $sp, $sp, 12
	
	addi $t8, $t8, 1
	j spawn_car_loop
	
	stop_spawning:
		jr $ra


check_collision:
	li $t0, 0	# $t0 = 0 = loop starting index (looping over array of existing enemy cars.. namely $s3 total cars)
	li $t4, 0	# returns value.. set to 1 if a collision did occurr!
	
	check_collision_loop:
	beq $t0, $s3, end_check_collision_loop	# branch if $t0 = $s3 (i.e. we've already looped through each car)
	
	# LOGIC BEHIND UPDATING A CAR'S POSITION!
	la $t9, ENEMY_CARS
	mul $t8, $t0, 4
	add $t9, $t9, $t8	# $t9 = addr(ENEMY_CARS) + ($t0 * 4) = address of $t0'th car in ENEMY_CARS (for position index)
	lw $t1, 0($t9)		# $t1 = *(addr(ENEMY_CARS) + ($t0 * 4)) = position index of $t0'th enemy car
	
	la $t8, CAR_DIRECTION
	mul $t7, $t0, 4
	add $t8, $t8, $t7	# $t8 = addr(CAR_DIRECTION) + ($t0 * 4) = address of $t0'th car in CAR_DIRECTION (for direction value)
	lw $t2, 0($t8)		# $t2 = *(addr(CAR_DIRECTION) + ($t0 * 4)) = direction value of $t0'th enemy car
	
	la $t9, CAR_LANE
	mul $t8, $t0, 4
	add $t9, $t9, $t8	# $t9 = addr(CAR_LANE) + ($t0 * 4) = address of $t0'th car in CAR_LANE (for lane number)
	lw $t3, 0($t9)		# $t2 = *(addr(CAR_LANE) + ($t0 * 4)) = lane number of $t0'th enemy car
	
	
	
	# Case 1: $t2 = 0 -> Car is moving DOWN (i.e. in Lane 1 or 2)
	bne $t2, 0, car_moving_up_case_cc
	
	lw $t5, LANE_3
	lw $t6, LANE_4
	beq $s7, $t5, resume_check_collision_loop	# Car can only move down on lanes 1 & 2 (so lane 3 case is ignored)
	beq $s7, $t6, resume_check_collision_loop	# Car can only move down on lanes 1 & 2 (so lane 4 case is ignored)
	
	
	# Recall: $t9 = address of $t0'th car index position, $t1 = value at that address
	#
	# A collision occurred if and only if any of the four corner pixels of the main car is within the "box-range" of police car
	# That means, if the top-left pixel of the main car (*(displayAddress) + $s7) is within the range between the top-left and bottom-right pixels of the
	# police car, which are $t1 and $t1 + ((9 - 1) x 4) + ((14 - 1) x 256) = $t1 + 3360, respectively. Hence, a collision occurred if and only if:
	#
	# $t1 <= *(displayAddress) + $s7 + 0 <= $t1 + 3360		# TOP-LEFT CORNER CHECK
	# 
	# OR:
	#
	# $t1 <= *(displayAddress) + $s7 + 32 <= $t1 + 3360		# TOP-RIGHT CORNER CHECK
	# 
	# OR:
	#
	# $t1 <= *(displayAddress) + $s7 + 3328 <= $t1 + 3360		# BOTTOM-LEFT CORNER CHECK
	#  
	# OR:
	#
	# $t1 <= *(displayAddress) + $s7 + 3360 <= $t1 + 3360		# BOTTOM-RIGHT CORNER CHECK
	
	bne $t3, $s7, resume_check_collision_loop	# branching since cars NOT IN SAME LANE! (which implies no collision)
	
	# TOP-LEFT CORNER CHECK
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	#addi $t7, $s7, 0				# $t7 += 0 (top-left corner)
	bgt $t1, $t7, try_top_right_pixel_case		# branch if $t1 > $t7 => !($t1 <= *(displayAddress + $s7 + 0))
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, try_top_right_pixel_case		# branch if $t7 > $t4 => !(*(displayAddress + $s7 + 0) <= $t1 + 3360)
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 1 to indicate a collision at lane 1!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	
	# TOP-RIGHT CORNER CHECK
	try_top_right_pixel_case:
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	addi $t7, $t7, 32				# $t7 += 32 (top-right corner)
	bgt $t1, $t7, try_bottom_left_pixel_case	# collision impossible -> so try other possible case for collisions
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, try_bottom_left_pixel_case	# collision impossible -> so try other possible case for collisions
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 2 to indicate a collision at lane 2!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	# BOTTOM-LEFT CORNER CHECK
	try_bottom_left_pixel_case:
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	addi $t7, $t7, 3328				# $t7 += 3328 (bottom-left corner)
	bgt $t1, $t7, try_bottom_right_pixel_case	# collision impossible -> so try other possible case for collisions
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, try_bottom_right_pixel_case	# collision impossible -> so try other possible case for collisions
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 3 to indicate a collision at lane 3!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	
	# BOTTOM-RIGHT CORNER CHECK
	try_bottom_right_pixel_case:
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	addi $t7, $t7, 3360				# $t7 += 3360 (bottom-right corner)
	bgt $t1, $t7, resume_check_collision_loop	# collision impossible -> so branch out to start of loop
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, resume_check_collision_loop	# collision impossible -> so branch out to start of loop
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 4 to indicate a collision at lane 4!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	
	# Case 2: $t2 = 1 -> Car is moving UP (i.e. in Lane 3 or 4)
	car_moving_up_case_cc:
	
	lw $t5, LANE_1
	lw $t6, LANE_2
	beq $s7, $t5, resume_check_collision_loop	# Car can only move up on lanes 3 & 4 (so lane 1 case is ignored)
	beq $s7, $t6, resume_check_collision_loop	# Car can only move up on lanes 3 & 4 (so lane 2 case is ignored)
	
	
	# Recall: $t9 = address of $t0'th car index position, $t1 = value at that address
	#
	# A collision occurred if and only if any of the four corner pixels of the main car is within the "box-range" of police car
	# That means, if the top-left pixel of the main car (*(displayAddress) + $s7) is within the range between the top-left and bottom-right pixels of the
	# police car, which are $t1 and $t1 + ((9 - 1) x 4) + ((14 - 1) x 256) = $t1 + 3360, respectively. Hence, a collision occurred if and only if:
	#
	# $t1 <= *(displayAddress) + $s7 + 3360 + 0 <= $t1 + 3360		# TOP-LEFT CORNER CHECK
	# 
	# OR:
	#
	# $t1 <= *(displayAddress) + $s7 + 3360 + 32 <= $t1 + 3360		# TOP-RIGHT CORNER CHECK
	# 
	# OR:
	#
	# $t1 <= *(displayAddress) + $s7 + 3360 + 3328 <= $t1 + 3360		# BOTTOM-LEFT CORNER CHECK
	#  
	# OR:
	#
	# $t1 <= *(displayAddress) + $s7 + 3360 + 3360 <= $t1 + 3360		# BOTTOM-RIGHT CORNER CHECK
	
	bne $t3, $s7, resume_check_collision_loop	# branching since cars NOT IN SAME LANE! (which implies no collision)
	
	# TOP-LEFT CORNER CHECK
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	#addi $t7, $s7, -3328				# extra 3328 needed (b/c of direction)
	#addi $t7, $s7, 0				# $t7 += 0 (top-left corner)
	bgt $t1, $t7, try_top_right_pixel_case2		# branch if $t1 > $t7 => !($t1 <= *(displayAddress + $s7 + 0))
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, try_top_right_pixel_case2		# branch if $t7 > $t4 => !(*(displayAddress + $s7 + 0) <= $t1 + 3360)
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 1 to indicate a collision at lane 1!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	
	# TOP-RIGHT CORNER CHECK
	try_top_right_pixel_case2:
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	#addi $t7, $s7, -3328				# extra 3328 needed (b/c of direction)
	addi $t7, $t7, 32				# $t7 += 32 (top-right corner)
	bgt $t1, $t7, try_bottom_left_pixel_case2	# collision impossible -> so try other possible case for collisions
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, try_bottom_left_pixel_case2	# collision impossible -> so try other possible case for collisions
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 2 to indicate a collision at lane 2!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	# BOTTOM-LEFT CORNER CHECK
	try_bottom_left_pixel_case2:
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	#addi $t7, $s7, -3328				# extra 3328 needed (b/c of direction)
	addi $t7, $t7, 3328				# $t7 += 3328 (bottom-left corner)
	bgt $t1, $t7, try_bottom_right_pixel_case2	# collision impossible -> so try other possible case for collisions
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, try_bottom_right_pixel_case2	# collision impossible -> so try other possible case for collisions
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 3 to indicate a collision at lane 3!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	
	# BOTTOM-RIGHT CORNER CHECK
	try_bottom_right_pixel_case2:
	lw $t7, displayAddress
	add $t7, $t7, $s7				# loading *(displayAddress) + $s7 into $t7
	#addi $t7, $s7, -3328				# extra 3328 needed (b/c of direction)
	addi $t7, $t7, 3360				# $t7 += 3360 (bottom-right corner)
	bgt $t1, $t7, resume_check_collision_loop	# collision impossible -> so branch out to start of loop
	addi $t4, $t1, 3360				# $t4 = $t1 + 3360
	bgt $t7, $t4, resume_check_collision_loop	# collision impossible -> so branch out to start of loop
	
	# This implies a collision occurred!
	li $t4, 1					# set $t4 (return value) to 4 to indicate a collision at lane 4!
	j end_check_collision_loop			# jump to end (we already detected a collision)
	
	resume_check_collision_loop:
		addi $t0, $t0, 1
		j check_collision_loop
	
	end_check_collision_loop:
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		jr $ra


determine_enemy_speed:
	lw $t1, SPEED_1
	lw $t2, SPEED_2
	lw $t3, SPEED_3
		
	#bne $s6, $t2, try_speed1_case	# branch if current speed != SPEED_2
	#lw $s6, SPEED_3
	#j keypress_handling_finished
		
	#try_speed1_case:
	#bne $s6, $t1, keypress_handling_finished	# branch if current speed != SPEED_1
	#lw $s6, SPEED_2

draw_one:
	lw $t9, displayAddressReal
	addi $t9, $t9, 40	# x-offset (10 width pixels)
	addi $t9, $t9, 256	# y-offset (1 height pixel)
	
	li $t7, 0x000000
	li $t8, 0xc92e34
	
	# LINE 1 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 2 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 3 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 4 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 5 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	jr $ra

draw_two:
	lw $t9, displayAddressReal
	addi $t9, $t9, 40	# x-offset (10 width pixels)
	addi $t9, $t9, 256	# y-offset (1 height pixel)
	
	li $t7, 0x000000
	li $t8, 0xFF7F7F
	
	# LINE 1 (1/5) 
	sw $t8, 0($t9)
	sw $t8, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 2 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 3 (1/5) 
	sw $t8, 0($t9)
	sw $t8, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 4 (1/5) 
	sw $t8, 0($t9)
	sw $t7, 4($t9)
	sw $t7, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 5 (1/5) 
	sw $t8, 0($t9)
	sw $t8, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	jr $ra

draw_three:
	lw $t9, displayAddressReal
	addi $t9, $t9, 40	# x-offset (10 width pixels)
	addi $t9, $t9, 256	# y-offset (1 height pixel)
	
	li $t7, 0x000000
	li $t8, 0xffffff
	
	# LINE 1 (1/5) 
	sw $t8, 0($t9)
	sw $t8, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 2 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 3 (1/5) 
	sw $t7, 0($t9)
	sw $t8, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 4 (1/5) 
	sw $t7, 0($t9)
	sw $t7, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	# LINE 5 (1/5) 
	sw $t8, 0($t9)
	sw $t8, 4($t9)
	sw $t8, 8($t9)
	addi $t9, $t9, 256
	
	jr $ra


draw_top_bar:
	lw $t0, displayAddressReal
	
	# Draw everything initially black
	li $t1, 0x000000
	li $t4, 0
	li $t5, 1792
	draw_top_bar_loop:
	beq $t4, $t5, continue_draw_top_bar
	
	
	add $t6, $t0, $t4
	sw $t1, 0($t6)
	
	addi $t4, $t4, 4
	j draw_top_bar_loop
	
	continue_draw_top_bar:
	
	li $t1, 0xffffff	# white
	li $t2, 0x7EC850	# white
	li $t3, 0xd81817	# red
	
	# Draw everything initially black
	
	#li $t4, 0
	#li $t5, 256
	#draw_top_bar_loop:
	#beq $t4, $t5, continue_draw_top_bar
	
	#add $t6, $t0, $t4
	#sw $t2, 0($t6)
	
	#addi $t4, $t4, 4
	#j draw_top_bar_loop
	
	#continue_draw_top_bar:
	addi $t0, $t0, 256
	
	sw $t3, 12($t0)
	sw $t3, 20($t0)
	
	addi $t0, $t0, 256
	
	sw $t3, 8($t0)
	sw $t3, 12($t0)
	sw $t3, 16($t0)
	sw $t3, 20($t0)
	sw $t3, 24($t0)
	sw $t1, 32($t0)
	
	addi $t0, $t0, 256
	
	sw $t3, 8($t0)
	sw $t3, 12($t0)
	sw $t3, 16($t0)
	sw $t3, 20($t0)
	sw $t3, 24($t0)
	
	addi $t0, $t0, 256
	
	sw $t3, 12($t0)
	sw $t3, 16($t0)
	sw $t3, 20($t0)
	sw $t1, 32($t0)
	
	addi $t0, $t0, 256
	
	sw $t3, 16($t0)
	
	#addi $t0, $t0, 256
	#addi $t0, $t0, 256
	
	#li $t4, 0
	#li $t5, 256
	#draw_top_bar_loop2:
	#beq $t4, $t5, continue_draw_top_bar2
	
	#add $t6, $t0, $t4
	#sw $t2, 0($t6)
	
	#addi $t4, $t4, 4
	#j draw_top_bar_loop2
	
	#continue_draw_top_bar2:
	bne $s1, 1, try_two_lives	# branch if num_lives != 1
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal draw_one
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j end_draw_top_bar
	
	try_two_lives:
	bne $s1, 2, try_three_lives	# branch if num_lives != 2
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal draw_two
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	j end_draw_top_bar
	
	try_three_lives:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal draw_three
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	end_draw_top_bar:
		jr $ra 
	
draw_game_over:
	lw $t0, displayAddressReal
	li $t8, 0xffffff
	li $t9, 0x000000
	# Draw everything initially white
	li $t4, 0
	li $t5, 16384
	draw_game_over_loop:
	beq $t4, $t5, continue_draw_game_over
	
	
	add $t6, $t0, $t4
	sw $t8, 0($t6)
	
	addi $t4, $t4, 4
	j draw_game_over_loop
	
	continue_draw_game_over:
	
	# Draw R
	lw $t0, displayAddressReal
	addi $t0, $t0, 13056 	# Height Offset
	addi $t0, $t0, 116	# Width Offset
	addi $t0, $t0, 32
	
	li $t1, 0xd8bd0d
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	# Draw Q
	lw $t0, displayAddressReal
	addi $t0, $t0, 13056 	# Height Offset
	addi $t0, $t0, 116	# Width Offset
	addi $t0, $t0, -32
	
	li $t1, 0xec1b23
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	
	sw $t1, 8($t0)
	addi $t0, $t0, 256
	
	
	sw $t1, 12($t0)
	addi $t0, $t0, 256
	
	# Draw Skull
	lw $t0, displayAddressReal
	addi $t0, $t0, 1792 	# Height Offset
	addi $t0, $t0, 80	# Width Offset
	
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	addi $t0, $t0, 256
	
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	addi $t0, $t0, 256
	
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 68($t0)
	sw $t9, 72($t0)
	addi $t0, $t0, 256
	
	sw $t9, 4($t0)
	sw $t9, 76($t0)
	addi $t0, $t0, 256
	
	sw $t9, 0($t0)
	sw $t9, 80($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 4($t0)
	sw $t9, 76($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 4($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 76($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 8($t0)
	
	sw $t9, 36($t0)
	sw $t9, 44($t0)
	
	sw $t9, 72($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -8($t0)
	sw $t9, 8($t0)
	sw $t9, 72($t0)
	sw $t9, 88($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 8($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	
	sw $t9, 40($t0)
	
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	
	sw $t9, 72($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 4($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 76($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, 0($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 72($t0)
	sw $t9, 80($t0)
	addi $t0, $t0, 256
	
	sw $t9, 0($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 72($t0)
	sw $t9, 80($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	
	sw $t9, 40($t0)
	
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 72($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 8($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 72($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, -4($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 84($t0)
	addi $t0, $t0, 256
	
	sw $t9, 0($t0)
	sw $t9, 20($t0)
	
	sw $t9, 36($t0)
	sw $t9, 44($t0)
	
	sw $t9, 60($t0)
	sw $t9, 80($t0)
	addi $t0, $t0, 256
	
	sw $t9, 4($t0)
	sw $t9, 16($t0)
	
	sw $t9, 64($t0)
	sw $t9, 76($t0)
	addi $t0, $t0, 256
	
	sw $t9, 8($t0)
	sw $t9, 12($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 68($t0)
	sw $t9, 72($t0)
	addi $t0, $t0, 256
	
	sw $t9, 8($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	
	sw $t9, 28($t0)
	sw $t9, 40($t0)
	sw $t9, 52($t0)
	
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 72($t0)
	addi $t0, $t0, 256
	
	sw $t9, 8($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	
	sw $t9, 28($t0)
	sw $t9, 40($t0)
	sw $t9, 52($t0)
	
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 72($t0)
	addi $t0, $t0, 256
	
	sw $t9, 8($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 72($t0)
	addi $t0, $t0, 256
	
	sw $t9, 8($t0)
	sw $t9, 16($t0)
	sw $t9, 20($t0)
	
	sw $t9, 28($t0)
	sw $t9, 40($t0)
	sw $t9, 52($t0)
	
	sw $t9, 60($t0)
	sw $t9, 64($t0)
	sw $t9, 72($t0)
	addi $t0, $t0, 256
	
	sw $t9, 12($t0)
	sw $t9, 20($t0)
	
	sw $t9, 28($t0)
	sw $t9, 40($t0)
	sw $t9, 52($t0)
	
	sw $t9, 60($t0)
	sw $t9, 68($t0)
	addi $t0, $t0, 256
	
	sw $t9, 16($t0)
	sw $t9, 64($t0)
	addi $t0, $t0, 256
	
	sw $t9, 16($t0)
	sw $t9, 64($t0)
	addi $t0, $t0, 256
	
	sw $t9, 20($t0)
	sw $t9, 24($t0)
	sw $t9, 56($t0)
	sw $t9, 60($t0)
	addi $t0, $t0, 256
	
	sw $t9, 28($t0)
	sw $t9, 32($t0)
	sw $t9, 36($t0)
	sw $t9, 40($t0)
	sw $t9, 44($t0)
	sw $t9, 48($t0)
	sw $t9, 52($t0)
	addi $t0, $t0, 256
	
	jr $ra
	
	
	
	
	
	
	
