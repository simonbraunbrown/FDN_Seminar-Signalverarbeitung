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

ishift      =           .00666667                          ;shift it 8/1200.
ipitch      =           cpspch(p5)                         ;convert parameter 5 to cps.
ioct        =           octpch(p5)                         ;convert parameter 5 to oct.
kadsr       linseg      0, p3/3, 1.0, p3/3, 1.0, p3/3, 0   ;ADSR envelope for output
kmod        linseg      0, p3/3, 5, p3/3, 3, p3/3, 0       ;ADSR envelope for I
kenv        linseg      p6, p3, p7                         ;moves from p6->p7 in p3 sec.
;ares        oscil       1, ipitch, 21  
ares2       oscil       1, ioct, 21
kamp1       =           kmod*((kenv-1)/kenv)/2
kamp2       =           kmod*((kenv+1)/kenv)/2

aindx1      =           abs(kamp1*1.5/20)                       ;kamp1 normalized between 0-1. for tbl 23

aamp3       tablei      aindx1, 23, 1                       ;lookup tbl in f23, normal index

aosc1       oscil       aamp3, ipitch, 22                   ;cosine
aosc2       oscil       kamp2*ares2, ipitch, 22                   ;cosine

aamp4       =           exp(-0.5*aamp3+aosc1)

aoutl       oscil       0.05*kadsr*aamp4, aosc2+cpsoct(ioct+ishift), 21 ;fnl outleft
aoutr       oscil       0.05*kadsr*aamp4, aosc2+cpsoct(ioct-ishift), 21 ;fnl outright

            outs        Sigmoide(aoutl), Sigmoide(aoutr)
            
            kd = ipitch
            
            printk 1, kd
            ;print octpch(p5)
            ;printks "kadsr=%f, kmod=%f, kenv=%f, kres=%f, kres2=%f \\n", 1, kadsr, kmod, kenv, kres, kres2
            ;printks "kres=%f, kres2=%f, kadsr=%f, kamp1=%f, kamp2=%f, kd=%f \\n", 1, kres, kres2, kadsr, kamp1, kamp2, kd
            ;dispfft	aoutl, .1, 2048, 0, 1
            
            
          
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

i1 0 80 1  4.01 1.0 0.1
i1 . . .  4.05 . .
i1 . . .  4.08 . .  
i1 . . .  3.01 . .
i1 . . .  3.05 . .  
i1 . . .  3.08 . .

i1 40 80 1  4.08 1.0 0.1
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  3.08 . .
i1 . . .  3.12 . .
i1 . . .  4.03 . .

i1 80 100 1  5.12 1.0 0.1
i1 . . .  6.03 . .
i1 . . .  6.07 . .
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  5.07 . .

i1 120 100 1 5.06 1.0 0.1
i1 . . .  5.10 . .
i1 . . .  6.01 . .
i1 . . .  4.06 . .
i1 . . .  4.10 . .
i1 . . .  5.01 . .

,,,,,,,,,,,,,,,,,,,,,,,,,

i1 160 80 1  4.01 1.0 0.1
i1 . . .  4.05 . .
i1 . . .  4.08 . .  
i1 . . .  3.01 . .
i1 . . .  3.05 . .  
i1 . . .  3.08 . .
i1 . . .  5.01 . .
i1 . . .  5.05 . .  
i1 . . .  5.08 . .

i1 200 80 1  4.08 1.0 0.1
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  3.08 . .
i1 . . .  3.12 . .
i1 . . .  4.03 . .
i1 . . .  5.08 . .
i1 . . .  5.12 . .
i1 . . .  6.03 . .

i1 240 80 1  5.12 1.0 0.1
i1 . . .  6.03 . .
i1 . . .  6.07 . .
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  5.07 . .
i1 . . .  6.12 . .
i1 . . .  7.03 . .
i1 . . .  7.07 . .

i1 280 100 1 5.06 1.0 0.1
i1 . . .  5.10 . .
i1 . . .  6.01 . .
i1 . . .  4.06 . .
i1 . . .  4.10 . .
i1 . . .  5.01 . .
i1 . . .  6.06 . .
i1 . . .  6.10 . .
i1 . . .  7.01 . .

,,,,,,,,,,,,,,,,,,,,,,,,,

i1 320 80 1  4.01 1.0 0.1
i1 . . .  4.05 . .
i1 . . .  4.08 . .  
i1 . . .  3.01 . .
i1 . . .  3.05 . .  
i1 . . .  3.08 . .
i1 . . .  5.01 . .
i1 . . .  5.05 . .  
i1 . . .  5.08 . .
i1 . . .  6.01 . .
i1 . . .  6.05 . .  
i1 . . .  6.08 . .

i1 360 80 1  4.08 1.0 0.1
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  3.08 . .
i1 . . .  3.12 . .
i1 . . .  4.03 . .
i1 . . .  5.08 . .
i1 . . .  5.12 . .
i1 . . .  6.03 . .
i1 . . .  6.08 . .
i1 . . .  6.12 . .
i1 . . .  7.03 . .

i1 400 80 1  4.12 1.0 0.1
i1 . . .  5.03 . .
i1 . . .  5.07 . .
i1 . . .  3.12 . .
i1 . . .  4.03 . .
i1 . . .  4.07 . .
i1 . . .  5.12 . .
i1 . . .  6.03 . .
i1 . . .  6.07 . .
i1 . . .  6.12 . .
i1 . . .  7.03 . .
i1 . . .  7.07 . .

i1 440 80 1 5.06 1.0 0.1
i1 . . .  5.10 . .
i1 . . .  6.01 . .
i1 . . .  4.06 . .
i1 . . .  4.10 . .
i1 . . .  5.01 . .
i1 . . .  6.06 . .
i1 . . .  6.10 . .
i1 . . .  7.01 . .
i1 . . .  7.06 . .
i1 . . .  7.10 . .
i1 . . .  8.01 . .

,,,,,,,,,,,,,,,,,,,,,,,,,

i1 480 80 1  4.08 1.0 0.1
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  3.08 . .
i1 . . .  3.12 . .
i1 . . .  4.03 . .
i1 . . .  5.08 . .
i1 . . .  5.12 . .
i1 . . .  6.03 . .
i1 . . .  6.08 . .
i1 . . .  6.12 . .
i1 . . .  7.03 . .

i1 520 80 1  4.08 1.0 0.1
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  3.08 . .
i1 . . .  3.12 . .
i1 . . .  4.03 . .
i1 . . .  5.08 . .
i1 . . .  5.12 . .
i1 . . .  6.03 . .

i1 560 80 1  5.12 1.0 0.1
i1 . . .  6.03 . .
i1 . . .  6.07 . .
i1 . . .  4.12 . .
i1 . . .  5.03 . .
i1 . . .  5.07 . .
i1 . . .  6.12 . .
i1 . . .  7.03 . .
i1 . . .  7.07 . .

i1 600 80 1 5.06 1.0 0.1
i1 . . .  5.10 . .
i1 . . .  6.01 . .
i1 . . .  4.06 . .
i1 . . .  4.10 . .
i1 . . .  5.01 . .
i1 . . .  6.06 . .
i1 . . .  6.10 . .
i1 . . .  7.01 . .

,,,,,,,,,,,,,,,,,,,,,,,,,

i1 640 80 1  4.01 1.0 0.1
i1 . . .  4.05 . .
i1 . . .  4.08 . .  
i1 . . .  3.01 . .
i1 . . .  3.05 . .  
i1 . . .  3.08 . .
i1 . . .  5.01 . .
i1 . . .  5.05 . .  
i1 . . .  5.08 . .

   
</CsScore>

</CsoundSynthesizer>
