
# REV7 
#  - The delay of 5 sec is fixed
# 
# REV8
#  - Increse plotting window to 20sec
#  - The output value is in nA
# REV9
#  - 60 Hz rejection
#%%
# First we import the library and init the FrontPanel object
import ok
import time
import statistics as st
import math
import csv
import pandas as pd
import numpy as np
from matplotlib import pyplot as plt
from datetime import datetime
from scipy import signal

def conv2A(list,LSB):
    return [(i-4096)*LSB/1e3 for i in list]
now = datetime.now()

current_time = now.strftime("%H_%M_%S")
print("Current Time =", current_time)

#==========================
# VARIABLES
TEST        = 0x00
RANGE       = 1
TINTMS      = 10 # in msec
win_size    = 20 # ~in sec 
filter      = 0
# f0          = 60.0  # Frequency to be removed from signal (Hz)
f0          = 60.0  # Frequency to be removed from signal (Hz)
cutoff          = 50.0  # Frequency to be removed from signal (Hz)
# cutoff          = 20  # Frequency to be removed from signal (Hz)
Q           = 30.0  # Quality factor
#==========================
fs = 1000/TINTMS  # Sample frequency (Hz)
# comment = '_baseline_wintan_wLED'
# comment = '_test_headstage_bulk2gnd'
comment = '_test_mono_noProbe_noise'
TINT = int(TINTMS*10000)
win_size_samp = win_size*5
C = 12.5e-12*RANGE
V = 4.096
T = TINTMS*1e-3
LSB = C*V/T/(2**20-1)*1e12; # pA
FSR = C*V/T*1e9; # nA
#%%

tintless05msec = ((TINT<5000));
tintless1msec = ((TINT<10000)& (TINT>5000-1));
tintless5msec = ((TINT<50000)& (TINT>10000-1));
tintless10msec = ((TINT<100000) &(TINT>50000-1));
tintmore10msec = (TINT>=100000);
sample_step = (400*tintless05msec+200*tintless1msec+50*tintless5msec+25*tintless10msec+20*tintmore10msec)
samples = sample_step;
msg_size = 32;
byte_outsize = samples*64/8;
datain = bytearray(int(byte_outsize))

## Prepare things for image 
fig = plt.figure()
ax2 = fig.add_subplot(1,1,1)
line, = ax2.plot([], lw=3)
ax2.set_xlim([0,TINTMS/1e3*(win_size_samp*samples)])
ax2.set_ylim([-4096*LSB/1e3, FSR])
ax2.set_ylabel('nA')
ax2.set_xlabel('sec')
fig.canvas.draw()   # note that the first draw comes before setting data 
ax2background = fig.canvas.copy_from_bbox(ax2.bbox)
plt.show(block=False)


dev = ok.okCFrontPanel()

#%% 
bitfilename='pipeout_testc1_fifo512'
# bitfilename='pipeout_testc1_fifo128'
# bitfilename='pipeout_testc1_MINI'
# Next we open the device and program it

error_OpenBySerial = dev.OpenBySerial("")
error_ConfigureFpga = dev.ConfigureFPGA(bitfilename+".bit");
#%% 
# Display some diagnostic code
print("Open by Serial Error Code: " + str(error_OpenBySerial))
print("Configure FPGA Error Code: " + str(error_ConfigureFpga))

dev.UpdateWireOuts()
dataa = dev.GetWireOutValue(0x20)
datab = dev.GetWireOutValue(0x21)
time.sleep(0.1)
print(dataa)
print(datab)

# ==== Send TEST ====
dev.SetWireInValue(0x01, TEST)
dev.UpdateWireIns()
print('the TEST value is ',TEST)
# ==== Send Range ====
dev.SetWireInValue(0x03, RANGE)
dev.UpdateWireIns()
time.sleep(0.2)
# ==== Send TINT ====
dev.SetWireInValue(0x04, TINT)
dev.UpdateWireIns()
print('the TINT value is ',TINT)
time.sleep(0.2)
# ==== GET RANGE ====
dev.UpdateWireOuts()
checked_range = dev.GetWireOutValue(0x23)
print('the range value is ',checked_range)
time.sleep(0.2)
 
# Send brief reset signal to initialize the FSM.
dev.SetWireInValue(0x02, 0xff);
dev.UpdateWireIns();

dev.SetWireInValue(0x02, 0x00);
dev.UpdateWireIns()
samplecnt=0

output_bin_list= []
output_bin_list_ch1= []
output_bin_list_ch2= []
output_dec_list_ch1= []
output_dec_list_ch2= []

x=[]
start_time = time.time()

# ==== Check fifo threshold value ====
dev.UpdateWireOuts()
fifo_thwire = dev.GetWireOutValue(0x24)
print('the FIFO threshold value is ',fifo_thwire)
# time.sleep(10)

print('now will extract the data')
try:
    x=TINTMS/1e3*np.array((range(samples*win_size_samp)))
    
    data2plot = [0]*samples*win_size_samp
    while True:
        dev.UpdateWireOuts()
        fifo_flag = dev.GetWireOutValue(0x22)
        if fifo_flag == True:
            data_seize_old = len(output_dec_list_ch2);
            samplecnt=samplecnt+sample_step
            data = dev.ReadFromPipeOut(0xA0, datain)
            
            outputbits = ''.join(format(byte, '08b')[::-1] for byte in datain)
            for i in range(samples):
                tempMSB=outputbits[msg_size*(2*i):msg_size*(2*i+1)]
                tempLSB=outputbits[msg_size*(2*i+1):msg_size*(2*i+2)]
                tempcmb=tempLSB+tempMSB
                output_bin = tempcmb[0:40]# MSB first
                output_bin_list.append(output_bin)
                output_bin_list_ch2.append(output_bin[0:20])
                output_bin_list_ch1.append(output_bin[20:40])
                output_dec_list_ch2.append(int(output_bin[0:20],2))
                output_dec_list_ch1.append(int(output_bin[20:40],2))
            line.set_data(x,np.array(data2plot))
            temp = output_dec_list_ch2[-sample_step:]
            temp1 = conv2A(temp,LSB)
            data2plot=data2plot[samples:]+temp1
            # print(data2plot)
            if (filter==1):
                # b, a = signal.iirnotch(f0, Q, fs)
                # data2plot = list(signal.lfilter(b, a, data2plot))
                # b2, a2 = signal.iirnotch(f0*2, Q, fs)
                # data2plot = list(signal.lfilter(b2, a2, data2plot)) 
                order=5
                nyq = 0.5 * fs
                normal_cutoff = cutoff / nyq
                b, a = signal.butter(order, normal_cutoff, btype='low', analog=False)

                # b, a = signal.butter(order, [1/nyq, normal_cutoff], btype='band', analog=False)

                data2plot = list(signal.lfilter(b, a, data2plot))
                # print(data2plot)
            fig.canvas.restore_region(ax2background)
            ax2.draw_artist(line)
            fig.canvas.blit(ax2.bbox)
            fig.canvas.flush_events()
            temp_sr = int((sample_step/(time.time() - start_time)))
            print('--- Sampling Rate %s --- Last Value - %s nA'  % (str(temp_sr).ljust(3),round(data2plot[-1],3)))
            start_time = time.time()
except KeyboardInterrupt:
    print('Done')
            
# print(output_dec_list_ch1)
print(output_dec_list_ch2)

def square(list):
    return [i ** 2 for i in list]
    
def sub(list,a):
    return [i -a for i in list]

mean_ch1 = st.mean(output_dec_list_ch1)
rms_ch1 = math.sqrt(st.mean(square(sub(output_dec_list_ch1,mean_ch1))))
print('ch1 mean')
print(mean_ch1)
print('ch1 rms')
print(rms_ch1)

mean_ch2 = st.mean(output_dec_list_ch2)
rms_ch2 = math.sqrt(st.mean(square(sub(output_dec_list_ch2,mean_ch2))))
print('ch2 mean')
print(mean_ch2)
print('ch2 rms')
print(rms_ch2)


# ==== Convert to current 
# CV=IT
# I = CV/T*code/(2^20-1)
Ich1 = C*V/T*(mean_ch1-2**12-1)/(2**20-1)*1e12; # pA
Ich2 = C*V/T*(mean_ch2-2**12-1)/(2**20-1)*1e12; # pA
print('input current value of ch1 is ',Ich1,'pA')
print('input current value of ch2 is ',Ich2,'pA')
print('LSB = ',LSB,'pA')
print('FSR = ',FSR,'nA')

# 


filename_raw= current_time+'_raw_'+bitfilename+'_'+str((TINTMS))+'ms_'+str(RANGE)+'_range'+comment+".csv"
filename= current_time+'_val_'+bitfilename+'_'+str((TINTMS))+'ms_'+str(RANGE)+'_range'+comment+".csv"

df = pd.DataFrame(data={"raw_ch2": output_dec_list_ch2})
df.to_csv("./data/"+filename_raw, sep=',',index=False)

df2 = pd.DataFrame(data={"I_ch1,pA": Ich1,"I_ch2,pA": Ich2,"Tint,sec": T,"C, F": C}, index=[0])
df2.to_csv("./data/"+filename, sep=',',index=False)



print("File is saved")




