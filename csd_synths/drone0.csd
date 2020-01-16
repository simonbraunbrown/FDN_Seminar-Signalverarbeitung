<CsoundSynthesizer>
<CsOptions>
-o dac 
;-i dac
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

opcode Sigmoide, a, a
	aX xin
	aPow = exp(aX*3.0)
	aOut = 2.0 * (1.0 / (1.0 + aPow))- 1.0
	xout aOut
endop

instr 1

ishift      =           .00666667                           ;shift it 8/1200.
ipch        =           cpspch(p5)                          ;convert parameter 5 to cps.
ioct        =           octpch(p5)                          ;convert parameter 5 to oct.
kadsr       linseg      0, p3/3, 1.0, p3/3, 1.0, p3/3, 0    ;ADSR envelope
kmodi       linseg      0, p3/3, 5, p3/3, 3, p3/3, 0        ;ADSR envelope for I
kmodr       linseg      p6, p3, p7                          ;r moves from p6->p7 in p3 sec.
a1          =           kmodi*(kmodr-1/kmodr)/2
a1ndx       =           abs(a1*2/20)                        ;a1*2 is normalized from 0-1.
a2          =           kmodi*(kmodr+1/kmodr)/2
a3          tablei      a1ndx, 23, 1                        ;lookup tbl in f23, normal index
ao1         oscil       a1, ipch, 22                        ;cosine
a4          =           exp(-0.5*a3+ao1)
ao2         oscil       a2*ipch, ipch, 22                   ;cosine
aoutl       oscil       0.05*kadsr*a4, ao2+cpsoct(ioct+ishift), 21 ;fnl outleft
aoutr       oscil       0.05*kadsr*a4, ao2+cpsoct(ioct-ishift), 21 ;fnl outright
            outs        Sigmoide(aoutl), Sigmoide(aoutr)

endin


</CsInstruments>

<CsScore>

;f tables for instr
f1  0 512   9 1 1 0                                    ;sine lo-res
f2  0 512   5 4096 512 1                               ;exp env
f3  0 512   9 10 1 0 16 1.5 0 22 2 0 23 1.5 0          ;inharm wave
f4  0 512   9 1 1 0                                    ;sine
f8  0 512   5 256 512 1                                ;exp env
f9  0 512   5 1   512 1                                ;constant value of 1
f10 0 512   7 0 50 1 50 .5 300 .5 112 0                ;ADSR
f11 0 2048 10 1                                        ;SINE WAVE hi-res
f13 0 1024  7 0 256 1 256 0 256 -1 256 0               ;triangle
f14 0 512   7 1 17  1 0   0 495                        ;pulse for S&H clk osc
f15 0 512   7 0 512 1 0                                ;ramp up;;;left=>right
f16 0 512   7 1 512 0 0                                ;ramp down;;;right=>left
f17 0 1024  7 .5 256 1 256 .5 256 0 256 .5             ;triangle with offset
f18 0 512   5 1 512 256                                ;reverse exp env
f20 0 1024 10 1 0 0 0 .7 .7 .7 .7 .7 .7                ;approaching square 

;f tables for instr 3
f21 0 8192 10 1 								   	   ;hughres sine wave
f22	0 8192 11 1     								   ;highres cosine wave
f23 0 8192 -12 20.0  								   ;unscaled ln(I(x)) from 0 to 20.0

   

;instr3    start 	dur 	gain 	freq 	amp    amp2
;p1 	  p2 	    p3      p4      p5      p6 	   p7	


; p5 shift octaves 
i1 0 30 1   4.06 1.0 0.2  
i1 . . .    5.01 . .  
i1 . . .    5.06 . .  
i1 . . .    5.10 . .   
i1 . . .    5.11 . .   
i1 . . .    6.04 . .   

i1 10 15 1  5.06 0.8 0.2 
i1 . . .    6.01 . .   
i1 . . .    6.06 . .   
i1 . . .    6.10 . .  
i1 . . .    6.11 . .   
i1 . . .    7.04 . .  

i1 20 80 1  4.06 1.0 0.2
i1 . . .    5.01 . .   
i1 . . .    4.06 . .  
i1 . . .    4.10 . .   
i1 . . .    4.11 . .   
i1 . . .    4.04 . .   
   
</CsScore>

</CsoundSynthesizer>
