# Currently only support [RemoveTracks] in config file
# need to change in maxscript:
# LoadPsaConfig ( (getFilenamePath filename) + (getFilenameFile filename) + (trackNum as string) + ".config" ) Anims Bones UseAnimTranslation AnimFlags
import os
import sys
refSeqNames = []
seqNamesFilePath = os.path.join(os.getcwd(), "seqNames.txt")
propPath = os.path.join(os.path.splitext(sys.argv[1])[0]+".props.txt")
configFilePath = sys.argv[1]
if not(os.path.exists(propPath) and os.path.exists(configFilePath)):
    print("need .config file and seqNames.txt")
    os.system("pause")
    exit()
print("Press to load ", sys.argv[1])
os.system("pause")

fp = open(propPath, "r")
data = fp.read().splitlines()
fp.close()
for line in data:
    if(line.find("//") == 0):
        refSeqNames.append(line.split("// Sequence: ")[1])

currentSeqIdx = -1
fp = open(configFilePath, "r")
configData = fp.read().splitlines()
fp.close()
seqNames = []
lastSeqName = None
lastBoneIdx = None
mode = 0
for line in configData:
    if not line:
        continue
    if(line == "[RemoveTracks]"):
        mode = 4
        continue
    if(mode == 4):
        seqName__boneIdx_flag = line.split(".")
        seqName = seqName__boneIdx_flag[0]
        boneIdx = int(seqName__boneIdx_flag[1].split("=")[0])
        flag = seqName__boneIdx_flag[1].split("=")[1]
        if((seqName != lastSeqName) or (boneIdx <= lastBoneIdx)):
            currentSeqIdx += 1
            seqIdx = refSeqNames[currentSeqIdx:].index(seqName)
            currentSeqIdx += seqIdx
            print(seqName, str(currentSeqIdx+1)+refSeqNames[currentSeqIdx])
            fp = open(os.path.join(os.path.splitext(sys.argv[1])[
                      0]+str(currentSeqIdx+1)+".config"), "w")
            fp.write("\n[RemoveTracks]\n")
        fp.write(line+"\n")
        lastSeqName = seqName
        lastBoneIdx = boneIdx
os.system("pause")
