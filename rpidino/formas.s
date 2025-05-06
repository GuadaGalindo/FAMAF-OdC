.ifndef formas_s
.equ formas_s, 0

    .equ SCREEN_WIDTH,   640
	.equ SCREEN_HEIGH,   480
	.equ BITS_PER_PIXEL, 32
    delay: .dword 0xfffff

    //COLORES:
    color_capibara: .word 0x994C00
    color_capibara_sombra: .word 0x7F3F00
	color_hocico: .word 0x844200
    color_fosas: .word 0x4E2700
    color_hocico_lineas: .word 0x763B00
    color_hocico_puntos: .word 0x5B2E00
	color_ojos: .word 0x331900
	color_cachetes: .word 0xFA8A7A
    color_negro_sombrero: .word 0x151515
    color_negro_sombra: .word 0x000000
    color_amarillo_sombrero: .word 0xFF8000
    color_amarillo_sombra: .word 0xE47200
    color_nube: .word 0xFFCBBF

//------------------------------FORMAS BASICAS------------------------------

/*
DRAW_PIXEL:

Argumentos:
x2 = posicion x
x3 = posicion y
x20 = direccion base del framebuffer
x10 = color
*/

draw_pixel:
        sub sp, sp, #8        //Salvamos los argumentos en el stack pointer
        stur lr, [sp]

        cmp x2, SCREEN_WIDTH  //Comparo la posicion de x para ver si es factible pintar
        b.hs end_draw_pixel
        cmp x3, SCREEN_HEIGH  //Comparo la posicion de y para ver si es factible pintar
        b.hs end_draw_pixel
        mov x9, SCREEN_WIDTH  //Seteo en x9 la direcion del pixel (x,y) "Direccion de inicio + 4 * [x + (y * 640)]"
        madd x9, x3, x9, x2
        lsl x9, x9 , #2 
        add x9, x20, x9
        stur w10, [x9]        //Pinto el pixel del color en x10
    end_draw_pixel:

        ldur lr, [sp]         //Recuperamos los argumentos del stack pointer
        add sp, sp, #8
    
        br lr                 //Return

/*
LINEA_VERTICAL:

Argumentos:
x2 = posicion en x
x3 = posicion inicial y
x4 = posicion final y
x10 = color
*/

linea_vertical:
        sub sp, sp, #16               //Salvamos los argumentos en el stack pointer
        stur lr, [sp]
        stur x3, [sp, #8]

    loop_linea_vertical:                 
        cmp x3, x4
        b.gt end_loop_linea_vertical  //Si termine de pintar la linea salto
        bl draw_pixel                 //Pinto el pixel N
        add x3, x3, #1                //Siguiente pixel
        b loop_linea_vertical
    end_loop_linea_vertical:

        ldur lr, [sp]                 //Recupero los argumentos del stack pointer
        ldur x3, [sp, #8] 
        add sp, sp, #16 

        br lr                         //Return

/*
LINEA_HORIZONTAL:

Argumentos:
x3 = posicion en y
x2 = posicion inicial x
x4 = posicion final x
x10 = color
*/

linea_horizontal:
        sub sp, sp, #16                 //Salvamos los argumentos en el stack pointer
        stur lr, [sp]
        stur x2, [sp, #8] 
    
    loop_linea_horizontal:
        cmp x2, x4
        b.gt end_loop_linea_horizontal  //Si termine de pintar la linea salto
        bl draw_pixel                   //Pinto el pixel N
        add x2, x2, #1                  //Siguiente pixel
        b loop_linea_horizontal
    end_loop_linea_horizontal:

        ldur lr, [sp]                   //Recupero los argumentos del stack pointer
        ldur x2, [sp, #8] 
        add sp, sp, #16 

        br lr                           //Return

/*
RECTANGULO: 

Argumentos:
x2 = posicion inicial x 
x3 = posicion inicial y
x4 = posicion final x
x5 = posicion final y 
w10 = color 
 */

rectangulo:
        sub sp, sp, #16            //Salvamos los argumentos en el stack pointer
        stur lr, [sp]
        stur x3, [sp, #8] 
    

    loop_rectangulo:
        cmp x3, x5
        b.gt end_loop_rectangulo   //Si termine de pintar todas la filas del rectangulo salto
        bl linea_horizontal        //Pinto linea N
        add x3, x3, #1             //Aumento la posicion de y en 1
        b loop_rectangulo
    end_loop_rectangulo:

        ldur lr, [sp]              //Recuperamos los argumentos del stack pointer
        ldur x3, [sp, #8] 
        add sp, sp, #16

        br lr                      //Return


/* 
CIRCULO:

Argumentos:
x2 = centro en x
x3 = centro en y
x4 = radio
x10 = color

Funciona recorriendo el cuadrado minimo que contiene al circulo, y en cada pixel decidiendo si pintar o no.
La forma de saber si un punto (x, y) esta en el circulo centrado en (x1, y1) de radio r es:

    (x - x1)^2 + (y - y1)^2 <= r^2
*/

circulo:
        sub sp, sp, #8                //Salvamos los argumentos en el stack pointer
        stur lr, [sp]

        mov x15, x2                   //Guardo en x15 la condenada del centro en x
        mov x16, x3                   //Guardo en x16 la condenada del centro en y
        add x17, x2, x4               //Guardo en x10 la posicion final en x
        add x11, x3, x4               //Guardo en x11 la posicion final en y
        mul x12, x4, x4               //x12 = r^2
        sub x2, x2, x4                //Pongo en x2 la posicion inicial en x

    loop0_circulo:                    //Loop para avanzar en x
        cmp x2, x17
        b.gt end_loop0_pintarCirculo
        sub x3, x11, x4 
        sub x3, x3, x4                //Pongo en x3 la posicion inicial en y

    loop1_circulo:                    //Loop para avanzar en y
        cmp x3, x11
        b.gt end_loop1_circulo        //Veo si tengo que pintar el pixel actual
        sub x13, x2, x15              //x13 = (x - x1)
        smull x13, w13, w13           //x13 = (x - x1)^2
        sub x14, x3, x16              //x14 = (y - y1)
        smaddl x13, w14, w14, x13     //x13 = (y - y1)^2 + (x - x1)^2
        cmp x13, x12
        b.gt fi_circulo 
        bl draw_pixel                 //Pinto el pixel N

    fi_circulo:
        add x3, x3, #1
        b loop1_circulo
    end_loop1_circulo:

        add x2, x2, #1
        b loop0_circulo
    end_loop0_pintarCirculo:

        mov x2, x15                   //Restauro en x2 la condenada del centro en x
        mov x3, x16                   //Restauro en x3 la condenada del centro en y

        ldur lr, [sp]                 //Recuperamos los argumentos del stack pointer
        add sp, sp, #8 

        br lr                         //Return

//---------------------------FUNCIONES DE IMAGEN---------------------------

/*
NUBES:

Argumentos:
x2 = centro en x
x3 = centro en y
x4 = radio

{- PRE: x4 >= 21 -}
*/

nube:
        sub sp, sp, #24                //Salvamos los argumentos en el stack pointer
        stur lr, [sp]
        stur x2, [sp, #8]
        stur x4, [sp, #16]

        ldr w10, color_nube           //Seteamos color nube
        bl circulo                    //Pinto circulo central
        mov x7, 2                     //x7 = Cuantos circulos de cada lado del central

    loop_nube_der:
        cbz x7, end_loop_nube_der     //Si termine de pintar los circulos de la der salto
        add x2, x2, x4                //x2 = x centro del circulo N (en la circunferencia del anterior)
        sub x4, x4, 10                //Disminuyo el radio en 10
        bl circulo                    //Pinto el circulo N
        sub x7, x7, 1                 //Decremento contador en 1
        b loop_nube_der
    end_loop_nube_der:

        ldur x2, [sp, #8]             //Recuperamos los argumentos iniciales
        ldur x4, [sp, #16]
        mov x7, 2                     //Seteo el contador

    loop_nube_izq:
        cbz x7, end_loop_nube_izq     //Si termine de pintar los circulos de la izq salto
        sub x2, x2, x4                //x2 = x centro del circulo N (en la circunferencia del anterior)
        sub x4, x4, 10                //Disminuyo el radio en 10
        bl circulo                    //Pinto el circulo N
        sub x7, x7, 1                 //Decremento contador en 1
        b loop_nube_izq
    end_loop_nube_izq:

        ldur lr, [sp]                 //Recuperamos los argumentos del stack pointer
        ldur x2, [sp, #8]
        ldur x4, [sp, #16]
        add sp, sp, #24

        br lr                         //Return

/*
PASTO:

Argumentos:
x2 = posicion x de inicio
x4 = ancho de un pasto
x3 = altura del pasto
x5 = posicion y de la base
x6 = cuantos pastos
w10 = color 

*/

pasto:
        sub sp, sp, #48                //Salvamos los argumentos en el stack pointer
        stur lr, [sp]
        stur x2, [sp, #8]
        stur x3, [sp, #16]
        stur x4, [sp, #24]
        stur x5, [sp, #32]
        stur x6, [sp, #40]

        mov x7, x4                     //Guardo la ancho de un pasto en x7
        add x4, x2, x4                 //x4 = posicion final de x para primer pasto

    loop_pasto:
        cbz x6, end_loop_pasto         //Si ya termine de pintar el largo de pastos salto
        bl rectangulo                  //Pinto pasto N
        sub x6, x6, 1                  //Decremento el contador en 1
        cbz x6, end_loop_pasto         //Si ya termine de pintar el largo de pastos salto
        add x2, x4, x7                 //x2 = nueva x un pasto N+1 (separado x7 del anterior)
        add x4, x4, x7                 //x4 = posicion final de x para pasto N+1
        add x4, x4, x7
        sub x3, x3, 10                 //x3 = nueva y un pasto N+1 (mas abajo que el anterior)
        sub x5, x5, 10                 //x5 = posicion final de y para pasto N+1
        bl rectangulo                  //Pinto pasto N+1
        sub x6, x6, 1
        cbz x6, end_loop_pasto         //Si ya termine de pintar el largo de pastos salto
        add x2, x4, x7                 //x2 = nueva x un pasto N+2 (separado x7 del anterior)
        add x4, x4, x7                 //x4 = posicion final de x para pasto N+2
        add x4, x4, x7
        add x3, x3, 20                 //x3 = nueva y un pasto N+2 (mas arriba que el anterior)
        add x5, x5, 20                 //x5 = posicion final de y para pasto N+2
        bl rectangulo                  //Pinto pasto N+2
        sub x6, x6, 1
        cbz x6, end_loop_pasto         //Si ya termine de pintar el largo de pastos salto
        add x2, x4, x7                 //x2 = nueva x un pasto N (separado x7 del anterior)
        add x4, x4, x7                 //x4 = posicion final de x para pasto N
        add x4, x4, x7
        sub x3, x3, 10                 //x3 = nueva y un pasto N (x3 inicial)
        sub x5, x5, 10                 //x5 = posicion final de y para pasto N (x5 inicial)
        b loop_pasto
    end_loop_pasto:

        ldur lr, [sp]                  //Recuperamos los argumentos del stack pointer
        ldur x2, [sp, #8]
        ldur x3, [sp, #16]
        ldur x4, [sp, #24]
        ldur x5, [sp, #32]
        ldur x6, [sp, #40]
        add  sp, sp, #48

        br lr                         //Return

/*
CAPIBARA:
*/

capibara:
        sub sp, sp, #8                 //Salvamos los argumentos en el stack pointer
        stur lr, [sp]

    Orejas:
	    ldr w10, color_capibara        //Seteo el color de la capibara
        mov x2, 220                    //x2 = x centro oreja izquierda
    	mov x3, 190                    //x3 = y centro oreja izquierda
	    mov x4, 30                     //x4 = radio orejas
	    bl circulo                     //Pinto oreja izquierda
        add x2, x2, 200                //x2 = x2 + "Distacia entre orejas"
	    bl circulo                     //Pinto orja derecha

    //DETALLES:
        ldr w10, color_capibara_sombra //Seteo el color de las orejas
        mov x2, 225                    //x2 = x centro detalle oreja izquierda
    	mov x3, 198                    //x3 = y centro detalle oreja izquierda
	    mov x4, 15                     //x4 = radio detalle orejas
	    bl circulo                     //Pinto detalle oreja izquierda
        add x2, x2, 190                //x2 = x2 + "Distacia entre detalles orejas"
	    bl circulo                     //Pinto detalle oreja derecha

    Cara:
        ldr w10, color_capibara        //Seteo el color de la capibara
	    mov x2, 320                    //x2 = x centro cara
	    mov x3, 290                    //x3 = y centro cara
	    mov x4, 125                    //x4 = radio cara
	    bl circulo                     //Pinto cara
	
    Cuerpo:
	    mov x2, 195                    //x2 = x inicial primer rectangulo del cuerpo
        mov x4, 445                    //x4 = x final primer rectangulo del cuerpo
	    mov x3, 290                    //x3 = y inicial primer rectangulo del cuerpo
	    add x5, x3, 10                 //x5 = x3 + "Altura del primer rectangulo"

    loop_cuerpo:    
        cmp x3, SCREEN_HEIGH          
        b.gt end_loop_cuerpo           //Si termine de pintar el cuerpo salto
	    bl rectangulo                  //Pinto el rectangulo N
        sub x2, x2, 1                  //Decremento x2 en 1
        add x4, x4, 1                  //Incremento x4 en 1 (esto genera un escalonado de 1 pixel por lado)
        mov x3, x5                     //x3 = "y inicial del rectangulo N" (empieza donde termina el aterior)
        add x5, x3, 10                 //x5 = x3 + "Altura del primer rectangulo"   
        b loop_cuerpo
    end_loop_cuerpo:

    //DETALLES:
        ldr w10, color_capibara_sombra
        mov x2, 195                    //x2 = x inicial primer rectangulo de sombra
        mov x4, 205                    //x4 = x final primer rectangulo de sombra
	    mov x3, 290                    //x3 = y inicial primer rectangulo de sombra
	    add x5, x3, 10                 //x5 = x3 + "Altura del primer rectangulo"

    loop_sombras:    
        cmp x3, SCREEN_HEIGH          
        b.gt end_loop_sombras          //Si termine de pintar las sombras
	    bl rectangulo                  //Pinto el rectangulo N
        sub x2, x2, 1                  //Decremento x2 en 1
        sub x4, x4, 1                  //Incremento x4 en 1 (esto genera un escalonado de 1 pixel por lado)
        mov x3, x5                     //x3 = "y inicial del rectangulo N" (empieza donde termina el aterior)
        add x5, x3, 10                 //x5 = x3 + "Altura del primer rectangulo"   
        b loop_sombras
    end_loop_sombras:

    Ojos:
	    ldr w10, color_ojos            //Seteo color ojos
        mov x3, 270                    //x3 = y inicial ojos
	    add x5, x3, 25                 //x5 = x3 + "Altura de los ojos"
        mov x2, 190                    //x2 = x inicial ojo izquierdo
        add x4, x2, 35                 //x4 = x2 + "Ancho de los ojos"
	    bl rectangulo                  //Pinto ojo izquierdo
	    add x2, x2, 225                //x2 = x2 + "Distancia entre las x iniciales de los ojos"
	    add x4, x2, 35                 //x4 = x2 + "Ancho de los ojos"
	    bl rectangulo  

    Cachetes:
	    ldr w10, color_cachetes        //Seteo color cachetes
        mov x3, 305                    //x3 = y inicial cachetes
        add x5, x3, 15                 //x5 = x3 + "Altura de los cachetes"
        mov x2, 210                    //x2 = x inicial cachete izquierdo
	    add x4, x2, 35                 //x4 = x2 + "Ancho de los cachetes"
	    bl rectangulo                  //Pinto cachete izquierdo
	    add x2, x2, 185                //x2 = x2 + "Distancia entre las x iniciales de los cachetes"
	    add x4, x2, 35                 //x4 = x2 + "Anchura de los cachetes"
	    bl rectangulo

    Hocico:
        //Hocico sombra:
        ldr w10, color_capibara_sombra //Seteo color hocico sombra
        mov x2, 317                    //x2 = x centro hocico sombra
	    mov x3, 333                    //x3 = y centro hocico sombra
	    mov x4, 65                     //x4 = radio hocico sombra
	    bl circulo                     //Pinto hocico sombra

        //Hocico:
	    ldr w10, color_hocico          //Seteo color hocico
        mov x2, 320                    //x2 = x centro hocico
	    mov x3, 330                    //x3 = y centro hocico
	    mov x4, 65                     //x4 = radio hocico
	    bl circulo                     //Pinto hocico

    //DETALLES:
        //Fosas nasales sombra:
        ldr w10, color_hocico_lineas   //Seteo color hocico lineas
        mov x2, 295                    //x2 = x centro fosas nasales sombra izquierda
	    mov x3, 318                    //x3 = y centro fosas nasales sombra
	    mov x4, 10                     //x4 = radio fosas nasales sombra
	    bl circulo                     //Pinto fosa nasal sombra izquierda
        mov x2, 345                    //x2 = x centro fosas nasales derecha
	    bl circulo                     //Pinto fosa nasal sombra derecha

        //Fosas nasales:
        ldr w10, color_fosas           //Seteo color fosas nasales
        mov x2, 295                    //x2 = x centro fosa nasal izquierda
	    mov x3, 315                    //x3 = y centro fosas nasales
	    mov x4, 10                     //x4 = radio fosas nasales
	    bl circulo                     //Pinto fosa nasal izquierda
        mov x2, 345                    //x2 = x centro fosa nasal derecha
	    bl circulo                     //Pinto fosa nasal derecha

        //Linea del medio:
        ldr w10, color_hocico_lineas   //Seteo color hocico lineas
        mov x3, 330                    //x3 = y inicial cachetes
        add x5, x3, 35                 //x5 = final del detalle
        mov x2, 315                    //x2 = x inicial cachete izquierdo
	    add x4, x2, 10                 //x4 = x2 + "Ancho de los cachetes"
	    bl rectangulo                  //Pinto cachete izquierdo    

        //Lineas de los costados:
        //Cortas abajo:
        mov x3, 366                    //x3 = y inicial 
        add x5, x3, 5                  //x5 = x3 + "Altura de linea"
        mov x2, 300                    //x2 = x inicial linea izquierda
	    add x4, x2, 14                 //x4 = x2 + "Ancho de linea"
	    bl rectangulo                  //Pinto linea izquierda
        mov x2, 325                    //x2 = x inicial linea derecha
	    add x4, x2, 14                 //x4 = x2 + "Ancho de linea"
	    bl rectangulo                  //Pinto linea derecha 

        //Cortas arriba:
        mov x3, 324                    //x3 = y inicial 
        add x5, x3, 5                  //x5 = x3 + "Altura de linea"
        mov x2, 300                    //x2 = x inicial linea izquierda
	    add x4, x2, 14                 //x4 = x2 + "Ancho de linea"
	    bl rectangulo                  //Pinto linea izquierda
        mov x2, 325                    //x2 = x inicial linea derecha
	    add x4, x2, 14                 //x4 = x2 + "Ancho de linea"
	    bl rectangulo                  //Pinto linea derecha

        //Largas abajo:
        mov x3, 371                    //x3 = y inicial
        add x5, x3, 5                  //x5 = x3 + "Altura de linea"
        mov x2, 277                    //x2 = x inicial linea izquierda
	    add x4, x2, 23                 //x4 = x2 + "Ancho de linea"
	    bl rectangulo                  //Pinto linea izquierda
        mov x2, 340                    //x2 = x inicial linea derecha
	    add x4, x2, 23                 //x4 = x2 + "Ancho de linea"
	    bl rectangulo                  //Pinto linea derecha  

        //Puntitos:
        ldr w10, color_hocico_puntos   //Seteo color hocico puntos
        mov x3, 338                    //x3 = y inicial 
        add x5, x3, 3                  //x5 = x3 + "Altura de los puntitos"
        mov x2, 305                    //x2 = x inicial 
	    add x4, x2, 3                  //x4 = x2 + "Ancho de los puntitos"
	    bl rectangulo                  //Pinto puntito (repito para los 6 puntitos)

        add x5, x3, 3
        mov x2, 333
	    add x4, x2, 3
	    bl rectangulo

        mov x3, 351
        add x5, x3, 3
        mov x2, 297
	    add x4, x2, 3
	    bl rectangulo

        add x5, x3, 3
        mov x2, 343
	    add x4, x2, 3
	    bl rectangulo

        ldur lr, [sp]                  //Recuperamos los argumentos del stack pointer
        add sp, sp, #8 

        br lr                          //Return

/*
SOMBRERO:
*/

sombrero:
    sub sp, sp, #8                     //Salvamos los argumentos en el stack pointer
    stur lr, [sp]

    //Sombra en la capibara:
    ldr w10, color_capibara_sombra     //Seteo el color capibara sombra
    mov x3, 187                        //x3 = y inicial sombra
    add x5, x3, 10                     //x5 = x3 + "Altura de la sombra"
    mov x2, 268                        //x2 = x inicial sombra
	add x4, x2, 96                     //x4 = x2 + "Anchura de la sombra"
	bl rectangulo                      //Pinto sombra en la capibara

    //Cuerpo del sombrero:
    ldr w10, color_negro_sombrero      //Seteo el color negro del sombrero
    mov x3, 184                        //x3 = y inicial base del sombrero
    add x5, x3, 10                     //x5 = x3 + "Altura de la base del sombrero"
    mov x2, 271                        //x2 = x inicial base del sombrero
	add x4, x2, 96                     //x4 = x2 + "Ancho de la base del sombrero"
	bl rectangulo                      //Pinto base del sombrero 

    mov x3, 104                        //x3 = y inicial sombrero
    add x5, x3, 80                     //x5 = x3 + "Altura de la base del sombrero"
    mov x2, 280                        //x2 = x inicial sombrero
	add x4, x2, 79                     //x4 = x2 + "Ancho del sombrero"
	bl rectangulo                      //Pinto el sombrero

    //Sombras del sombrero:
    ldr w10, color_negro_sombra        //Seteo color sombra base del sombrero
    mov x3, 184                        //x3 = y inicial sombra
    add x5, x3, 10                     //x5 = x3 + "Altura de la sombra"
    mov x2, 271                        //x2 = x inicial sombra
	add x4, x2, 15                     //x4 = x2 + "Ancho de la sombra"
	bl rectangulo                      //Pinto sombra base del sombrero 

    mov x3, 104                        //x3 = y inicial sombra
    add x5, x3, 80                     //x5 = x3 + "Altura de la sombra"
    mov x2, 280                        //x2 = x inicial sombra
	add x4, x2, 15                     //x4 = x2 + "Ancho de la sombra"
	bl rectangulo                      //Pinto sombra del sombrero 

    //linea del sombrero:
    ldr w10, color_amarillo_sombrero   //Seteo el color linea del sombrero
    mov x3, 178                        //x3 = y inicial linea
    add x5, x3, 5                      //x5 = x3 + "Altura de la linea"
    mov x2, 280                        //x2 = x inicial linea
	add x4, x2, 79                     //x4 = x2 + "Ancho de la linea"
	bl rectangulo                      //Pinto linea del sombrero

    //sombra de la linea del sombrero:
    ldr w10, color_amarillo_sombra     //Seteo el color sombra linea
    mov x3, 178                        //x3 = y inicial sombra
    add x5, x3, 5                      //x5 = x3 + "Altura de la sombra"
    mov x2, 280                        //x2 = x inicial sombra
	add x4, x2, 10                     //x4 = x2 + "Ancho de la sombra"
	bl rectangulo                      //Pinto sombra de la linea


    ldur lr, [sp]                     //Recuperamos los argumentos del stack pointer
    add sp, sp, #8

    br lr                            //Return

.endif
/*x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 x18 */