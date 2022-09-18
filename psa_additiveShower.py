import sys
import os
if not(sys.argv[1]):
    print("need .props.txt")
    os.system("pause")
    exit()
propPath = sys.argv[1]
seqIdx = 0
fp = open(propPath, "r")
data = fp.read().splitlines()
fp.close()
seqName = None
additiveAnimType = None
refPoseType = None
refPoseSeq = None
refFrameIndex = None
skeleton = None
seqs = []
for line in data:
    if(line.find("//") == 0):
        seqName = line.split("// Sequence: ")[1]
        seqIdx += 1
    if(line.find("AdditiveAnimType") == 0):
        additiveAnimType = line.split("AdditiveAnimType = ")[1]
    if(line.find("RefPoseType = ") == 0):
        refPoseType = line.split("RefPoseType = ")[1]
    if(line.find("RefPoseSeq = ") == 0):
        refPoseSeq = line.split("RefPoseSeq = ")[1]
    if(line.find("RefFrameIndex = ") == 0):
        refFrameIndex = int(line.split("RefFrameIndex = ")[1])
    if(line.find("Skeleton = ") == 0):
        skeleton = line.split("Skeleton = ")[1]

    if(skeleton):
        if(additiveAnimType != "AAT_None (0)" or refPoseType != "ABPT_None (0)" or refPoseSeq != "None" or refFrameIndex != 0):
            print("%-5s" % seqIdx, "%-50s" % str(str(seqIdx)+seqName),
                  additiveAnimType, refPoseType, refFrameIndex)
            if(refPoseSeq):
                print(refPoseSeq)
            print()
        seqName = None
        additiveAnimType = None
        refPoseType = None
        refPoseSeq = None
        refFrameIndex = None
        skeleton = None
