	.include "formas.s"
	.equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32

	.equ GPIO_BASE,    0x3f200000
	.equ GPIO_GPFSEL0, 0x00
	.equ GPIO_GPLEV0,  0x34
	.equ GPIO_W, 0b000010

	//COLORES
	color_cielo: .word 0xF03D19
	color_pasto_base: .word 0x69B528
    color_pasto: .word 0x99CC00
	color_sol: .word 0xEC6F21
	.globl main 

main:
	mov x20, x0 // Guarda la direccion base del framebuffer en x20
	//------------------------CODE HERE --------------------------

    //FONDO:

	    //Cielo:
	    mov x2, 0
		mov x4, 640
	    mov x3, 0
	    add x5, x3, 10
		ldr w10, color_cielo

    loop_cielo:    
        cmp x5, 190        
        b.gt end_loop_cielo
	    bl rectangulo
        mov x3, x5
        add x5, x3, 10
		add x10, x10, 0x500
		add x10, x10, 0x5
        b loop_cielo
    end_loop_cielo:

	    //Nubes:
	    //Izquierda
	    mov x2, 130
		mov x3, 105
		mov x4, 35
		bl nube
        
		//Derecha
		mov x2, 500
		mov x3, 50
		mov x4, 31
		bl nube
	
	    //Sol:
        mov x2, 320
		mov x3, 190
		mov x4, 120
		ldr w10, color_sol
		bl circulo

	    //Fondo pasto:
	    mov x2, 0
		mov x4, 640
		mov x3, 191
	    mov x5, 480
	    ldr w10, color_pasto_base
	    bl rectangulo

	    //Pastos:
	    mov x1, 25  
		mov x2, 0
		mov x4, 3
		mov x3, 180
		add x5, x3, x1
		mov x6, 320
		ldr w10, color_pasto

	loop_pastos:
		cmp x3, SCREEN_HEIGH
		b.gt end_loop_pastos
		bl pasto
		add x1, x1, 5
		add x3, x5, 5
		add x5, x3, x1
		sub x10, x10, 0xF0000
		sub x10, x10, 0xF00
		b loop_pastos
	end_loop_pastos:

	//CAPIBARA:
	    bl capibara
	    
		mov w6, 1
    InfLoop:
	 
	 	mov x9, GPIO_BASE
		ldr w7, [x9, GPIO_GPLEV0]

		AND w13, w7, GPIO_W
	

		sub W13, w13, GPIO_W
		cbz w13, sombrero // Al apretar la tecla w se pone el sombrero  
		
	


	

        b InfLoop

