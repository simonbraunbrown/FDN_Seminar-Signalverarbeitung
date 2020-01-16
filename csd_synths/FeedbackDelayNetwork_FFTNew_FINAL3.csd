<CsoundSynthesizer>
<CsOptions>
-o dac -i adc
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

gaSig_1, gaSig_2 init 0
gaNetworkSig init 0

gi12Root init 1.0594630944

gkNetworkFFTArray[] init 1024
kArr1[] fillarray 1, 2, 3, 4, 5

opcode Sigmoide, a, a
	aX xin
	aPow = exp(aX*3.0)
	aOut = 2.0 * (1.0 / (1.0 + aPow))- 1.0
	xout aOut
endop

opcode ExpFalloff , k, kk
	kX, kFalloff xin
	kOut = 1/ (1 + kFalloff * pow(kX,2))
	xout kOut
endop

gaSig init 0

giSine ftgen 0, 0, 2^10, 10, 1   

instr 1

aInSig inch 1

;FFT Analyze
kAvg init 0
kLastAnalysis init 0
kContrast init 0

fSig pvsanal aInSig, 1024, 256, 1024, 1
kLastAnalysis += ksmps/sr
		if (kLastAnalysis > 0.2) then
			kFrame pvs2tab gkNetworkFFTArray, fSig
	
			kAvg = 0
			kI = 0				
loop_1:
					kAvg += gkNetworkFFTArray[kI*2]
loop_lt kI, 1, 512, loop_1
	
		;Make Avg:
			kAvg/= 512
		
		; Measure Contrase
		kContrast = 0
			kI = 0
loop_2:
					kContrast += abs(gkNetworkFFTArray[kI*2] - kAvg)
loop_lt kI, 1, 512, loop_2
		
		kContrast/= 512
		;printk 0, kContrast
		;printk 0, kAvg
	
		kLastAnalysis = 0
endif
;End FFT Analyze


kpch1 = 4
kpch2 = 7

if (kAvg > 0.11) then
kpch1 = 7
kpch2 = 12
endif

; Oscilators:
aoscil1 poscil3 1.0, kContrast*50000, -1
aoscil2 poscil3 1.0, kContrast*50000* pow(gi12Root, kpch1), -1
aoscil3 poscil3 1.0, kContrast*50000* pow(gi12Root, kpch2), -1
asigComb = aoscil1 + aoscil2 + aoscil3



; Read Buffer
	aDelayRead1 delayr 1
	aDelaySig1 deltapi 0
	aDelaySig2 deltapi 0.5
	kRootMeanSquared rms gaSig

	; Write to buffer
	delayw 0.7* asigComb + 0.5 * (gaSig * ExpFalloff(0.5*kRootMeanSquared, 1.0))


; combine:
gaSig reson (aDelaySig1+aDelaySig2), 500, 1500, 2
	
; TIMOS: -----------------------------------------------	
	kEnv    loopseg  0.3, 0, 0, 0, 0.0005, 1, 0.1, 0, 1.9, 0, 0	
	kRand   randomh  400, 2000, 0.5
	aEnv    interp   kEnv
	
	aSig    poscil   aEnv, kRand, giSine            									
		
	if p4 == 1 then
 		adel1 poscil 0.0523, 0.023, giSine
 		adel2 poscil 0.073, 0.023, giSine, 0.5
	else
 		adel1 randi 0.05, 0.1, 2
 		adel2 randi 0.08, 0.2, 2
	endif
	
	aBufOut delayr 1
	aTab1   deltap   0.1373                 																			
	aTab2   deltap   0.2197
	aTab3   deltap   0.4139             																			
	aTab4   deltap   0.7234
 delayw   aSig + (aTab4*0.7)

aTimoSigLeft = aSig + ((aTab2+aTab4)*0.9)
aTimoSigRight = aSig + ((aTab1+aTab3)*0.9)
;gaNetworkSig lowpass2 Sigmoide(0.4*aDelaySig2 + 0.6*aTimoSig), 1000, 300
gaNetworkSig = Sigmoide(0.4*aDelaySig2 + 0.3*aTimoSigLeft + 0.3 * aTimoSigRight)
aout1 = Sigmoide(0.6*aTimoSigLeft) * 0.1 + Sigmoide(0.4*aDelaySig2) * 0.3
aout2 = Sigmoide(0.6*aTimoSigRight) * 0.1 + Sigmoide(0.4*aDelaySig2) * 0.3
aout1 butterbp  aout1, 300, 400
aout2 butterbp  aout2, 300, 400
outs aout1, aout2
endin


; ///////////////////////////////////////////////////////////////////////////////////////////////////


opcode Curves, k, kkk
	kXIn, kPresetShaping, kSlope xin
	if (kPresetShaping == 0) then
		kX = 1.0 - pow(abs(kXIn), kSlope)
	elseif (kPresetShaping == 1) then
		kX = pow(cos($M_PI * kXIn / 2.0), kSlope)
	elseif (kPresetShaping == 2) then
		kX = pow(abs(sin($M_PI * kXIn / 2.0)), kSlope)
	elseif (kPresetShaping == 3) then
		kX = pow(min(cos($M_PI * kXIn / 2.0), 1.0 - abs(kXIn)), kSlope)
	elseif (kPresetShaping == 4) then
		kX = 1.0 - pow(max(0.0, abs(kXIn) * 2.0 - 1.0), kSlope)
	endif

	xout kX
endop

#define FFTSIZE #1024#
#define BINS #$FFTSIZE/2#

gkArr[] init $FFTSIZE
gkAmp[] init $BINS
gkHarmFrq[] init $BINS 
gkRealFrq[] init $BINS 
gkAmpSorted[] init $BINS
gkHarmFrqSorted[] init $BINS 
gkRealFrqSorted[] init $BINS

gkFrequenceSimon1 init 50
gkFrequenceSimon2 init 50
gkFrequenceSimon3 init 50
gkFrequenceSimon4 init 50

instr 2
	kThresDb = -20
	kThres = ampdb(kThresDb)
	kMinTim = 1.0
	kLastAnalysis init i(kMinTim)
	kLastAnalysis += ksmps/sr

	fSig pvsanal gaNetworkSig, $FFTSIZE, $FFTSIZE/4, $FFTSIZE, 1
	kRms rms gaNetworkSig
	if (kRms > kThres && kLastAnalysis > kMinTim) then 
		kFrame pvs2tab gkArr, fSig
		event "i", 3, 0, 1
		kLastAnalysis = 0
	endif
	
	
	kTimerSimon init 0
	kTimerSimon += ksmps/sr
	kRandTimeSimon init 5
	if(kTimerSimon >= kRandTimeSimon) then
		kTimerSimon = 0
		kRandTimeSimon rand 30, 0.5, 0, 10
		
		kRnd1 random 0, 15
		kRnd2 random 0, 15
		kRnd3 random 0, 15
		kRnd4 random 0, 15
		
		kMidi1 = round(12 * (log(gkFrequenceSimon1/220)/log(2)) + 57) - 48
		kvalKai1 pchmidinn kMidi1
		kMidi2 = round(12 * (log(gkFrequenceSimon2/220)/log(2)) + 57) - 48
		kvalKai2 pchmidinn kMidi2
		kMidi3 = round(12 * (log(gkFrequenceSimon3/220)/log(2)) + 57) - 48
		kvalKai3 pchmidinn kMidi3
		kMidi4 = round(12 * (log(gkFrequenceSimon4/220)/log(2)) + 57) - 48
		kvalKai4 pchmidinn kMidi4

		printf "hello, the value is %f %f", 1, kMidi1, kvalKai1
	
		event "i", "simonPad", 0, 5 + kRnd1, 1000, kvalKai1, 1.0, 0.05
		event "i", "simonPad", 0, 5 + kRnd2, 1000, kvalKai2, 1.0, 0.05
		event "i", "simonPad", 0, 5 + kRnd3, 1000, kvalKai3, 1.0, 0.05
		event "i", "simonPad", 0, 5 + kRnd4, 1000, kvalKai4, 1.0, 0.05
	endif
	

endin

instr 3
	kCount = 0
	kI = 2
	loop_1:
		kMidi = round(12 * (log(gkArr[kI + 1]/220)/log(2)) + 57) - 0
		kHarmFreq cpsmidinn kMidi
		gkHarmFrq[kCount] = kHarmFreq
		gkRealFrq[kCount] = gkArr[kI + 1]

		gkAmp[kCount] = -1
		if(gkArr[kI + 1] > 50 && gkArr[kI + 1] < 16000) then
			gkAmp[kCount] = gkArr[kI]
		endif
		
		kCount += 1
	loop_lt kI, 2, $FFTSIZE, loop_1

	kTabI = 0
	loop_2:
		kMax maxarray gkAmp
		kI = 0
		kFound = 0	
		loop_3:
		if (gkAmp[kI] == kMax && kFound == 0) then
			gkHarmFrqSorted[kTabI] = gkHarmFrq[kI]
			gkRealFrqSorted[kTabI] = gkRealFrq[kI]
			gkAmpSorted[kTabI] = gkAmp[kI]
			gkAmp[kI] = -1
			kFound = 1
		endif
		loop_lt kI, 1, $BINS, loop_3
	loop_lt kTabI, 1, $BINS, loop_2

	krangeMin init 0.5
	krangeMax init 1
	kcpsmin init 2
	kcpsmax init 3

	ksp rspline krangeMin, krangeMax, kcpsmin, kcpsmax
	kRnd random -1, 1

	kSt1 = 0
	kSt2 = 0
	kSt3 = 0

	if(kRnd <= 0) then
		kSt1 = 3
		kSt2 = 7
		kSt3 = 10
	else
		kSt1 = -2
		kSt2 = -5
		kSt3 = -9
	endif

	kNumInstr = 2

	;	printk 0, gkHarmFrqSorted[0]
	gkFrequenceSimon1 = gkRealFrqSorted[0]
	gkFrequenceSimon2 = gkRealFrqSorted[1]
	gkFrequenceSimon3 = gkRealFrqSorted[3]
	gkFrequenceSimon4 = gkRealFrqSorted[7]

	event "i", 4, 0, 15, 0.1 * ksp, gkHarmFrqSorted[0]
	event "i", 4, ksp, 10, 0.07 * ksp, gkHarmFrqSorted[0] * semitone(kSt1)
	event "i", 4, ksp * 2, 8, 0.04 * ksp, gkHarmFrqSorted[0] * semitone(kSt2)
	event "i", 4, ksp * 3, 5, 0.01 * ksp, gkHarmFrqSorted[0] * semitone(kSt3)

	turnoff
endin

instr 4
	kAmp = p4
	iFrq = p5
	aImp mpulse 0.9, p3
	iQ ntrpol 10, 300, 1
	aMode mode aImp, iFrq, iQ
	aEnv linseg 0, p3/2, 1, p3/2, 0

	kNumActive active p1

	outs Sigmoide(aMode*aEnv*kAmp * 20), Sigmoide(aMode*aEnv*kAmp * 20)
endin

instr leanderWobble
	kamp       =          p5*50 ; Amplitude
	kfreq      expseg     0.001, p3/2, p4, p3/2, 0.001 ; Base frequency
	iloopnum   =          p6 ; Number of all partials generated
	alyd1      init       0
	alyd2      init       0
	           seed       0
	kfreqmult  oscili     1, 2, 1
	kosc       oscili     1, 2.1, 1
	ktone      randomh    0.5, 2, 0.2 ; A random input
	icount     =          1

	loop: ; Loop to generate partials to additive synthesis
	kfreq      =          kfreqmult * kfreq
	atal       oscili     1, 0.5, 1
	apart      oscili     1, icount*exp(atal*ktone) , 1 ; Modulate each partials
	anum       =          apart*kfreq*kosc
	asig1      oscili     kamp, anum, 1
	asig2      oscili     kamp, 1.5*anum, 1 ; Chorus effect to make the sound more "fat"
	asig3      oscili     kamp, 2*anum, 1
	asig4      oscili     kamp, 2.5*anum, 1
	alyd1      =          (alyd1 + asig1+asig4)/icount ;Sum of partials
	alyd2      =          (alyd2 + asig2+asig3)/icount
	           loop_lt    icount, 1, iloopnum, loop ; End of loop

	aEnv       linseg     0, p3*0.5, 1, p3*0.5, 0 
	           outs       alyd1*aEnv, alyd2*aEnv ; Output generated sound
endin

instr alexWobbly
    ispb = p3                    ; Seconds-per-beat. Must specify "1" in score
    p3 = ispb * p4               ; Reset the duration
    idur = p3                    ; Duration
    ires random 0.4, 2           ; Range 0.4 - 2         
    iamp = ires                  ; Amplitude 
    ires random 5.01, 7.01       ; Range 5 - 7           
    ipch = cpspch(ires)            ; Pitch
    idivision = 1 / (p7 * ispb)  ; Division of Wobble
    ; Oscillators
    a1 vco2 iamp, ipch * 1.005, 0
    a2 vco2 iamp, ipch * 0.495, 10
    a1 += a2
    ; Wobble envelope shape
    itable ftgenonce 0, 0, 8192, -7, 0, 4096, 1, 4096, 0
    
    ; LFO for wobble sound
    klfo oscil 1, idivision, itable
    ; Filter
    ibase = ipch
    imod = ibase * 9
    a1 moogladder a1, ibase + imod * klfo, 0.6
    
    ; Output
    out a1
endin

gaSimonSig init 0
instr simonPad

ishift      =           .00666667               ;shift it 8/1200.
ipch        =           cpspch(p5)              ;convert parameter 5 to cps.
ioct        =           octpch(p5)              ;convert parameter 5 to oct.
kadsr       linseg      0, p3/3, 1.0, p3/3, 1.0, p3/3, 0 ;ADSR envelope
kmodi       linseg      0, p3/3, 5, p3/3, 3, p3/3, 0 ;ADSR envelope for I
kmodr       linseg      p6, p3, p7              ;r moves from p6->p7 in p3 sec.
a1          =           kmodi*(kmodr-1/kmodr)/2
a1ndx       =           abs(a1*2/20)            ;a1*2 is normalized from 0-1.
a2          =           kmodi*(kmodr+1/kmodr)/2
a3          tablei      a1ndx, 23, 1             ;lookup tbl in f23, normal index
ao1         oscil       a1, ipch, 22             ;cosine
a4          =           exp(-0.5*a3+ao1)
ao2         oscil       a2*ipch, ipch, 22        ;cosine
aoutl       oscil       0.1 * 0.06*kadsr*a4, ao2+cpsoct(ioct+ishift), 21 ;fnl outleft
aoutr       oscil       0.1 * 0.1*kadsr*a4, ao2+cpsoct(ioct-ishift), 21 ;fnl outright
				        outs       Sigmoide(aoutl), Sigmoide(aoutr)

endin

</CsInstruments>
	<CsScore>
		;f tables for robin pad
		f21 0 8192 10 1 								   	   ;hughres sine wave
		f22	0 8192 11 1     								   ;highres cosine wave
		f23 0 8192 -12 20.0  								   ;unscaled ln(I(x)) from 0 to 20.0
		f 1 0 128 10 1
		i 1 0 300
		i 2 0 300
	</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>74</x>
 <y>404</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
