.model small

.stack 100h

.data
    ivesti db "Iveskite eilute:"
    enteris db 10, 13, "$"
    buferis db 255
    viso_simboliu db ?
    eilute db 255 dup (?)
    isvesti db "Rezultatas yra:", 10, 13, "$"
.code
    start:
        mov ax, @data
        mov ds, ax
        
        mov ah, 9
        mov dx, offset ivesti
        int 21h ;isvedamas pranesimas 
        
        mov ah, 0Ah
        mov dx, offset buferis
        int 21h ;ivedama eilute
        
        mov ah, 9
        mov dx, offset enteris
        int 21h ;isvedamas enteris
        
        mov bx, offset eilute ;bx irasomas eilutes adresas
        mov cl, viso_simboliu ;cl irasoma, kiek buvo simboliu
        
        ciklas:
            didzioji:
            mov dl, 'A'
            mov dh, 'Z'
            cmp [bx], dl ;jeigu maziau, simbolio nekeicia
            jb nekeisti
            cmp [bx], dh  ;jeigu daugiau, tikrina, ar nera mazoji
            ja mazoji
            add byte ptr [ds:bx], 20h   ;jeigu didzioji, pavercia mazaja
            jmp nekeisti      ;nusoka i gala, kad atgal nepaverstu didziaja
            
            mazoji:
            cmp [bx], 'a'  ;jeigu maziau, reiskia, nei mazoji, nei didzioji
            jb nekeisti
            cmp [bx], 'z'      ; jeigu daugiau, nei mazoji, nei didzioji
            ja nekeisti
            sub byte ptr [bx], 20h    ;mazoji, pavercia didziaja
            
            nekeisti:
            inc bx  ;adresas perstumiamas vienu i prieki
            dec cl  ;neperziuretu simboliu adresas sumazinamas per 1
            cmp cl, 0  ; palygina su 0
            jne ciklas ;jei likusiu simboliu ne 0, grizta i cikla
        
        mov byte ptr [ds:bx], '$' ;pakeistos eilutes gale iraso pabaigos zenkla
        
        mov ah, 9
        mov dx, offset isvesti  ;rezultato pranesimas
        int 21h
        
        mov ah, 9
        mov dx, offset eilute    ;isveda redaguota eilute
        int 21h
        
        mov ah, 4Ch
        mov al, 0
        int 21h
    end start
    