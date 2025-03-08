global main

section .data
    secuenciaBinariaA           db  0x43, 0x2D, 0x80, 0xD9, 0xD8, 0x44, 0x8A, 0xF8  ; Cadena a codificar
								db	0xB3, 0x07, 0x24, 0x97, 0x6F, 0xFD, 0x3D, 0x81 
								db	0x7F, 0xAD, 0x93, 0xFD, 0x84, 0xC6, 0x76, 0x1B

                        
    largoSecuenciaA             db 0x18 ; 0x18 24 bytes

    TablaConversion db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    saltoLinea db 0xA                 ; Salto de línea 
    
section .bss
    indiceCadenaDecodificada resb 1         ; Indice para almacenar valores codificados.
    indiceGrupoBytes resb 1                 ; Indice para trabajar bloques de 3 bytes sin codificar.
    temp resb 3                             ; Temp para leer y almacenar bytes sin codificar (bloques de 3).
    bloques6bits resb 4                     ; Variables para generar/almacenar temporalmente valores codificados (4 de 6 bits).
    caracterCodificado resb 4               ; Variables para almacenar los valores ya mapeados.
    secuenciaImprimibleA resb 32            ; Cadena codificada final.
    largoSecuenciaCodificada resb 4         ; Se reserva memoria para almacenar el largo de la cadena codificada.
    
section .text
main:
    ;Inializacion de indices.
        mov byte [indiceCadenaDecodificada], 0                      ; Se establece indice en 0 (redundante pero por las dudas).   
        mov byte [indiceGrupoBytes], 0                              ; Se establece indice en 0 (redundante pero por las dudas).
        jmp bucle_principal                                         ; Salto al bucle principal

                                                                                                                                                                                                                    
bucle_principal:
    ;Condicion del bucle
        movzx rax, byte [largoSecuenciaA]                           ; Se mueve el largo de la secuencia a rax
        imul rax, rax, 4                                            ; Se multiplica el largo x 4
        xor rdx, rdx                                                ; Se limpia el registro rdx (de no hacerlo los calculos en 64 bits podrian fallar)
        mov bl, 3                                                   ; Se almacena el 3 en bl
        div bl                                                      ; Se divide rax por 3
        mov [largoSecuenciaCodificada], rax                         ; Se almacena el largo que tendra la cadena codificada (4/3 la longitud sin codificar)
                
        movzx eax, byte [largoSecuenciaCodificada]                  ; Se almacena el largo de la cadena codificada en eax
        cmp byte [indiceCadenaDecodificada], al                     ; Se compara el indice con el largo
        jge imprimir_cadena                                         ; Cuando sean iguales es porque se almaceno toda la cadena codificada y falta imprimirla por pantalla


    ;Lectura y almacenado temporal de bytes sin codificar   
        ; Primer byte  
        movzx eax, byte [indiceGrupoBytes]                          ; Se almacena el indice en eax.
        mov al, [secuenciaBinariaA + eax]                           ; Se almacena en al el byte segun el indice.
        mov [temp], al                                              ; Se guardan los primeros bytes en temp[0]. Temp[0] tendra siempre los primeros bytes sin codificar.

        ; Segundo byte
        inc byte [indiceGrupoBytes]                                 ; Se incrementa el indice para avanzar.
        movzx eax, byte [indiceGrupoBytes]                          ; Se almacena el indice en eax.
        mov al, [secuenciaBinariaA + eax]                           ; Se almacena en al el byte segun el indice.
        mov [temp + 1], al                                          ; Se guardan los segundos bytes en temp[1]. Temp[1] tendra siempre los segundos bytes sin codificar.

        ; Tercer byte
        inc byte [indiceGrupoBytes]                                 ; Se incrementa el indice para avanzar.
        movzx eax, byte [indiceGrupoBytes]                          ; Se almacena el indice en eax.
        mov al, [secuenciaBinariaA + eax]                           ; Se almacena en al el byte segun el indice.
        mov [temp + 2], al                                          ; Se guardan los terceros bytes en temp[2]. Temp[2] tendra siempre los terceros bytes sin codificar.
        inc byte [indiceGrupoBytes]                                 ; Se incrementa el indice para avanzar.

        
    ;Proceso de codificacion
        ; Bloque 1: Primeros 6 bits del primer byte.
        mov al, [temp]                                              ; Se carga a al el primer byte.
        mov byte [bloques6bits], al                                 ; Mueve el byte a bloques6bits[0].
        shr byte [bloques6bits], 2                                  ; Se desplaza el numero y se agregan ceros a izquierda, almacenando asi los primeros 6 bits del primer byte. 

        ; Bloque 2: Ultimos 2 bits del primer byte y primeros 4 de segundo byte.
        mov al, [temp + 1]                                          ; Se carga a al el segundo byte.    
        shr al, 4                                                   ; Se desplaza el segundo byte 4 unidades a la derecha.
        shl byte [temp], 4                                          ; Se desplaza el primer byte 4 unidades a la izquierda.
        and byte [temp], 0x3F                                       ; Se aplica un and 00111111 para borrar primeros 2 bits.
        or al, [temp]                                               ; Se aplica OR para agregar 1s donde haga falta.
        mov [bloques6bits + 1], al                                  ; Se mueve el segundo valor codificado a bloques6bits[0].

        ; Bloque 3: Ulimos 4 bits del segundo byte y primeros dos bits del tercer byte.
        mov al, [temp + 1]                                          ; Se carga el segundo byte sin codificar a al.
        mov byte [bloques6bits + 2], al                             ; Se almacena el valor de al en bloques6bits[2].
        and byte [bloques6bits + 2], 0x0F                           ; Se aplica AND 00001111 para borrar los primeros 4 bits.
        shl byte [bloques6bits + 2], 2                              ; Se desplaza 2 unidades a izquierda.
        mov al, [temp + 2]                                          ; Se almacena en al el tercer byte sin codificar.
        shr byte al, 6                                              ; Se desplaza el byte 6 unidades a derecha.
        or byte [bloques6bits + 2], al                              ; Se aplica OR para agregar 1s donde haga falta.

        ; Bloque 4: Ultimos 6 bits del tercer byte
        mov al, [temp + 2]                             ; Se carga a al el tercer byte sin codificar.
        mov byte [bloques6bits + 3], al                ; Se carga el tercer byte a bloques6bits[3].
        shl byte [bloques6bits + 3], 2                 ; Se desplaza 2 unidades a izquierda.
        shr byte [bloques6bits + 3], 2                 ; Se desplaza el numero, quedando asi los ultimos 6 bits del tercer byte.


    ;Mapeo
        lea rsi, [TablaConversion]                     ; Se almacena la primera direccion de memoria de la tabla.
        
        ; Bloque 1:
        mov al, [bloques6bits]                         ; Se carga el primer byte por codificar a al.
        movzx rax, al                                  ; Se expande el registro al a uno de 64 bits (necesario para las proximas operaciones).
        movzx rbx, byte [rsi + rax]                    ; Se almacena en tbx la direccion de memoria del primer elemento de la tabla + el numero que representa el caracter codificado.
        mov [caracterCodificado], bl                   ; Se almacena el byte menos significativo (el unico que contiene el valor codificado) a caracterCodificado[0].

        ; Bloque 2:
        mov al, [bloques6bits + 1]                     ; Se carga el segundo byte por codificar a al.
        movzx rax, al                                  ; Se expande el registro al a uno de 64 bits (necesario para las proximas operaciones).
        movzx rbx, byte [rsi + rax]                    ; Se almacena en tbx la direccion de memoria del primer elemento de la tabla + el numero que representa el caracter codificado.
        mov [caracterCodificado + 1], bl               ; Se almacena el byte menos significativo (el unico que contiene el valor codificado) a caracterCodificado[1].

        ; Bloque 3    
        mov al, [bloques6bits + 2]                     ; Se carga el tercer byte por codificar a al.
        movzx rax, al                                  ; Se expande el registro al a uno de 64 bits (necesario para las proximas operaciones).
        movzx rbx, byte [rsi + rax]                    ; Se almacena en tbx la direccion de memoria del primer elemento de la tabla + el numero que representa el caracter codificado.
        mov [caracterCodificado + 2], bl               ; Se almacena el byte menos significativo (el unico que contiene el valor codificado) a caracterCodificado[2].

        ; Bloque 4:   
        mov al, [bloques6bits + 3]                     ; Se carga el cuarto byte por codificar a al.
        movzx rax, al                                  ; Se expande el registro al a uno de 64 bits (necesario para las proximas operaciones).
        movzx rbx, byte [rsi + rax]                    ; Se almacena en tbx la direccion de memoria del primer elemento de la tabla + el numero que representa el caracter codificado.
        mov [caracterCodificado + 3], bl               ; Se almacena el byte menos significativo (el unico que contiene el valor codificado) a caracterCodificado[3].



    ;Almacenamiento del mapeo en la cadena final
        ; Bloque 1:
        movzx eax, byte [indiceCadenaDecodificada]              ; Se carga el indice en eax y se lo expande.
        lea ebx, [secuenciaImprimibleA + eax]                   ; Se almacena la dirección de secuenciaImprimibleA + indice para luego poder almacenar en la cadena codificada final.
        mov al, [caracterCodificado]                            ; Se almacena el caracter codificado en al.
        mov [ebx], al                                           ; Se almacena el caracter codificado en la cadena codificada final.
        add byte [indiceCadenaDecodificada], 1                  ; Se incrementa el indice para avanzar.

        ; Bloque 2:
        movzx eax, byte [indiceCadenaDecodificada]              ; Se carga el indice en eax y se lo expande.
        lea ebx, [secuenciaImprimibleA + eax]                   ; Se almacena la dirección de secuenciaImprimibleA + indice para luego poder almacenar en la cadena codificada final.
        mov al, [caracterCodificado + 1]                        ; Se almacena el caracter codificado en al.
        mov [ebx], al                                           ; Se almacena el caracter codificado en la cadena codificada final.
        add byte [indiceCadenaDecodificada], 1                  ; Se incrementa el indice para avanzar.                        

        ; Bloque 3      
        movzx eax, byte [indiceCadenaDecodificada]              ; Se carga el indice en eax y se lo expande.
        lea ebx, [secuenciaImprimibleA + eax]                   ; Se almacena la dirección de secuenciaImprimibleA + indice para luego poder almacenar en la cadena codificada final.
        mov al, [caracterCodificado + 2]                        ; Se almacena el caracter codificado en al.
        mov [ebx], al                                           ; Se almacena el caracter codificado en la cadena codificada final.
        add byte [indiceCadenaDecodificada], 1                  ; Se incrementa el indice para avanzar.                                

        ; Bloque 4:     
        movzx eax, byte [indiceCadenaDecodificada]              ; Se carga el indice en eax y se lo expande.
        lea ebx, [secuenciaImprimibleA + eax]                   ; Se almacena la dirección de secuenciaImprimibleA + indice para luego poder almacenar en la cadena codificada final.
        mov al, [caracterCodificado + 3]                        ; Se almacena el caracter codificado en al.
        mov [ebx], al                                           ; Se almacena el caracter codificado en la cadena codificada final.
        add byte [indiceCadenaDecodificada], 1                  ; Se incrementa el indice para avanzar.                                    
    

    ;Volver al bucle
        jmp bucle_principal                                     ; Se llama de nuevo al bucle.


imprimir_cadena:
    mov eax, 4                                                  ; Llamada a write.
    mov ebx, 1                                                  ; Stdout.
    mov ecx, secuenciaImprimibleA                               ; Se almacena en ecx el puntero a la cadena a imprimir.
    mov edx, [largoSecuenciaCodificada]                         ; Se almacena el largo de la cadena.
    int 0x80                                                    ; Llamada al sistema.
    mov eax, 4                                                  ; Llamada a write.
    mov ebx, 1                                                  ; Stdout.
    mov ecx, saltoLinea                                         ; Se almacena el puntero al salto de linea.
    mov edx, 1                                                  ; Se almacena la longitud del salto de linea.
    int 0x80                                                    ; Llamada al sistema.
    jmp finalizar_programa                                      ; Se llama a finalizar_programa.


finalizar_programa:
    ; Finalizacion del programa
    mov eax, 1                                                   ; Llamada a exit.
    xor ebx, ebx                                                 ; Forzar ebx en 1.
    int 0x80                                                     ; Llamada al sistema.



section .note.GNU-stack noalloc noexec nowrite progbits          ; Linea necesaria para la compilacion