.model small

    skaitymo_dydis equ 20   ;konstantos
    rasymo_dydis equ 100

.stack 100h

.data
                                                 
    msg_pagalba db "Programa pakeicia skaitmenis i zodzius$"
    fduom db 20 dup(0)
    frez db 20 dup(0)
    skaitymo_buferis db skaitymo_dydis dup (?)
    rasymo_buferis db rasymo_dydis dup (?)
    d_deskriptorius dw ?   ;duomenu failo identifikacinis 16baitu skaicius
    r_deskriptorius dw ?   ;rezultatu failo identifikacinis 16baitu skaicius
    nulis db "nulis"
    vienas db "vienas"
    du db "du"
    trys db "trys"
    keturi db "keturi"
    penki db "penki"
    sesi db "sesi"
    septyni db "septyni"
    astuoni db "astuoni"
    devyni db "devyni"
    msg db "pavyko$"
    
.code
    start:
        mov ax, @data  ;i ax registra perkeliama nuoroda i data
        mov ds, ax     ;ds registro inicializacija
        
        lea si, fduom   ; i si irasomas fduom adresas
        mov bx, 82h     ; es registre nuo 81 baito saugomi parametrai, 81 - tarpas
        mov cx, 0
		
        duomenu_failo_skaitymas:
            mov ax, es:[bx]  ;i ax perduodama nuoroda i pirmaji parametro simboli
            inc bx
            
            cmp al, 20h  ;lyginama ar tarpas
            je tarpas1  
            
            cmp al, 13   ;lyginama ar nauja eilute
            je pagalba   ;jeigu po duomenu failo nieko nera, tai rez failas nepateiktas, klaida
            
            cmp ax, "?/" ; sukeista, nes pirmas simbolis saugomas zemesniam baite, o antras aukstesniam
            je pagalba   ;jeigu aptikta pagalba, reikia baigti darba
            
            mov byte ptr [si], al ;nuskaitytas simbolis perkeliamas pavadinimo buferi
            inc si;padidinamas adresas
			inc cl
            jmp duomenu_failo_skaitymas
            
		tarpas1:
		cmp cl, 0 
		je duomenu_failo_skaitymas
		jmp rezultatu_failo_skaitymas
		
		tarpas2:
		cmp cl, 0
		je ciklas
		jmp atidarymas_skaitymui
			
		pagalba:
		mov ah, 9
		mov dx, offset msg_pagalba   ;perduoda i dx nuoroda i pagalbos zinute
		int 21h
		jmp pabaiga
            
        rezultatu_failo_skaitymas:
		mov cx, 0
		lea si, frez   ; i si perduodama nuoroda i duomenu failo pavadinimo buferio pirma elementa
		ciklas:
			mov ax, es:[bx]  ;i ax perduodama nuoroda pirmo simbolio po duomenu failo pavadinimo es registre
			inc bx
			
			cmp al, 20h
			je tarpas2 
			
			cmp al, 13
			je atidarymas_skaitymui

			cmp ax, "?/"
			je pagalba
			
			mov byte ptr [si], al   ;perkeliamas simbolis i pavadinimo buferi
			inc si
			inc cl
		jmp ciklas
                
        atidarymas_skaitymui:
        
            mov ah, 3dh
            mov al, 00   ;nurodo kokiu rezimu atidaryt faila, 0 - skaitymui
            mov dx, offset fduom  ;perduodama nuoroda i duomenu failo pavadibima
            int 21h
            
            jc pagalba    ;jeigu carry flagas 1, tai ivyko atidarymo klaida
            mov d_deskriptorius, ax ;issaugomas failo deskriptoriaus numeris
            
        ;atidarymas_rasymui:
        
		mov ah, 3ch
		mov cx, 0    ;nustato file attribute i normal
		mov dx, offset frez  ;perduodama nuoroda i rez failo pavadinima
		int 21h
		
		jc pagalba ;jeigu cf=1, ivyko klaida, soksta i pagalba
		mov r_deskriptorius, ax ;issaugomas failo deskriptoriaus numeris
            
        apdorojimas:
            mov bx, d_deskriptorius ;i bx perduoda deskriptoriu
            call skaitymas ;kvieciama skaitymo funkcija, i stacka nupusinamas jos adresas ir perduodamas valdymas
            
            cmp ax, 0  ;po interupto, ax registre reiksme kiek nuskaityta simboliu
            je  uzdaryti_rfaila  ;jeigu nuskaityta 0 simboliu, failo pabaiga
            
            push ax  ;i steka perduodama ax reiksme, kad ja butu galima modifikuoti, bet veliau naudoti
            mov cx, ax  ;cx saugos indeksa, kuris nuskaityto failo simbolis apdorojamas dabar
            
            mov si, offset skaitymo_buferis ; i si perduodama nuoroda i skaitymo buferi
            mov di, offset rasymo_buferis   ; i di perduodama nuoroda i rasymo buferi
            
            tikrinimas: ;tikrina ar nuskaitytas simbolis yra skaitmuo
                mov dl, [si]   ; i dl perkeliama reiksme i kuria rodo nuoroda
                
                cmp dl, '0'    ; jeigu simbolis maziau uz 0, tai tikrai ne skaitmuo
                jb nekeisti
                
                cmp dl, '9'    ;jeigu simbolis daugiau uz 9, tai tikrai ne skaitmuo
                ja nekeisti
                
                push cx  ; jeigu simbolis skaitmuo, tai atlaisvinamos registru reiksmes, kad nebutu prarandamos
                push ax
                push si
                
                call skaicius ;kvieciama funkcija, kuri iterps skaitmens zodi
                
                pop si ; ta pacia tvarka sugrazinamos registru reiksmes
                pop ax
                add ax, cx ;cx bus i buferi irasytu simboliu skaicius
                
                dec ax  ;ax rodo kiek is viso simboliu rasymo registre, sumazinama per 1, nes pats skaitmuo nebus rasomas
                pop cx  ; grazinama cx reiksme saugoti dabartinio apdorojamo simbolio indeksui
                jmp keisti
                
                nekeisti: ;jeigu nebuvo skaitmuo
                    mov [di], dl ;nepakeistas simbolis perkeliamas i skaitymo buferi
                    inc di  ;padidinama nuoroda per viena elementa
                
                keisti:    
                    inc si ;jeigu pakeista, tai pries tai ivykdyti padidinimai atlikti funkcijoje, dabar tik padidinti skaitoma indeksa
            loop tikrinimas
            
            mov cx, ax ;i cx nurodoma kiek simboliu reikes irasyti
            mov bx, r_deskriptorius  ; ibx perkeliamas deskriotirius
            call rasymas ;kvieciama rasymo funkcija
            
            pop ax  ;grazinama i ax registra reiksme kiek buvo nuskaityta simboliu
            cmp ax, skaitymo_dydis ;jeigu simboliu buvo nuskaityta maziau nei max buferis, pasiekta pabaiga
            je apdorojimas ;jeigu ne pabaiga, skaito toliau
                  
        uzdaryti_rfaila: ;uzdaro rezultatu faila
            mov ah, 3eh
            mov bx, r_deskriptorius  ;perduodamas deskriptorius
            int 21h
              
        uzdaryti_d_faila: ;uzdaro duomenu faila
            mov ah, 3eh
            mov bx, d_deskriptorius  ;perduodamas deskriptorius
            int 21h 
                 
        pabaiga:
            mov ah, 4ch
            mov al, 0  ;viskas ivyko be klaidu
            int 21h
            
    proc skaitymas    ;skaitymo funkcija
        push cx   ;atlaisvinami registrai, kad nebutu prarasti duomenys
        push dx
        
        mov ah, 3fh
        mov cx, skaitymo_dydis ;nurodo max buferio dydi
        mov dx, offset skaitymo_buferis ;perduodama nuoroda
        int 21h
        
        pop dx     ;grazinami pries interupta buve registru duomenys
        pop cx
        ret   ;ispusinamas proceduros adresas is stacko, grazinamas valdymas
        
    skaitymas endp ;zymi proceduros aprasymo pabaiga
    
    proc rasymas   ;rasymo funkcija
        push dx
        
        mov ah, 40h
        mov dx, offset rasymo_buferis ;perduodamas buferio adresas
        int 21h
        
        pop dx
        ret
     endp rasymas
    
    proc skaicius
        mov si, 0  ;registras naudojamas zodzio simboliams indeksuoti
        cmp dl, '0'
        jne one
        mov bx, offset nulis ;perduoda nuoroda i zodi
        mov cx, 5  ;zymi zodzio simboliu skaiciu
        jmp prideti
        
        one:
        cmp dl, '1'
        jne two
        mov bx, offset vienas
        mov cx, 6
        jmp prideti
        
        two:
        cmp dl, '2'
        jne three
        mov bx, offset du
        mov cx, 2
        jmp prideti
        
        three:
        cmp dl, '3'
        jne four
        mov bx, offset trys
        mov cx, 4
        jmp prideti
        
        four:
        cmp dl, '4'
        jne five
        mov bx, offset keturi
        mov cx, 6
        jmp prideti
        
        five:
        cmp dl, '5'
        jne six
        mov bx, offset penki
        mov cx, 5
        jmp prideti
        
        six:
        cmp dl, '6'
        jne seven
        mov bx, offset sesi
        mov cx, 4
        jmp prideti
        
        seven:
        cmp dl, '7'
        jne eight
        mov bx, offset septyni
        mov cx, 7
        jmp prideti
        
        eight:
        cmp dl, '8'
        jne nine
        mov bx, offset astuoni
        mov cx, 7
        jmp prideti
        
        nine:
        mov bx, offset devyni
        mov cx, 6
        
        prideti:
		  cmp si, cx ;jeigu dar nebuvo irasyti visi simboliai, rasomas su dabartiniu indeksu
		  je grizti ;kitaip baigia darba
		  mov al, bx[si] ;i al irasoma dabartinis zodzio simbolis
		  mov [di], al  ;al esantis simbolis irasomas i rasymo buferio dabartini elementa
		  inc di     ;padidinama buferio nuoroda per 1
		  inc si    ;padidina skaiciu kuris rodo kiek buvo jau irasyta simboliu
		jmp prideti
        
        grizti:
        ret
    endp skaicius    
        
    end start 