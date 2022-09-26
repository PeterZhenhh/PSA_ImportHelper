
pluginManager.loadClass FBXEXP

global AX_IMPORTER_VERSION = 138


global g_lastDir1
global g_lastDir2
global g_lastDir3
global g_haveAnim
-- global g_lowerBody
-- global g_pelvis
-- global g_spineName
global Anims
global BoneRotationArray
global BoneLocationArray
global FrameBoneRotationArray
global FrameBoneLocationArray
global XMap
global YMap
global ZMap
global AixMap
global AddType
global boneNum
global FrameBoneFlag


global BaseAnimFileName
global AddAnimFileName
global CfgFileName


struct AnimInfoBinary
(
	Name,
	Address
)


struct BoneRotation
(
	Index,
	BoneName,
	ValueX,
	ValueY,
	ValueZ
)


fn ReadAnimInfoBinary bstream =
(
	v = AnimInfoBinary ()
	v.Name                = (getFileNameFile(bstream))
	v.Address             = bstream
	v
)


fn SaveValue Num BoneName X Y Z =
(
	w = BoneRotation()
	w.Index    = Num
	w.BoneName = BoneName
	w.ValueX    = X
	w.ValueY    = Y
	w.ValueZ    = Z
	w
)

-- configure FBX exporter
fn SetupFBX =
(
	-- http://www.the-area.com/forum/autodesk-fbx/fbx-plug-ins-import-export-discussions/maxscript-export-dialog-properties/
	-- both commands should be used to ensure all commands are functional
	pluginManager.loadClass FBXIMP
	pluginManager.loadClass FBXEXP

	-- FbxExporterSetParam "Geometries" true -- <bool>
	-- Controls the state of the "Geometries" checkbox in the FBX Export dialog.
	FbxExporterSetParam "NormalsPerPoly" true -- <bool>
	-- Controls the state of the "Support normals per polygon vertex" checkbox in the FBX Export dialog.
	FbxExporterSetParam "Cameras" false -- <bool>
	-- Controls the state of the "Cameras" checkbox in the FBX Export dialog.
	FbxExporterSetParam "Lights" false -- <bool>
	-- Controls the state of the "Lights" checkbox in the FBX Export dialog.
	FbxExporterSetParam "GeomAsBone" true -- <bool>
	-- Controls the state of the "Geometries used as bones, exported as bones" checkbox in the FBX Export dialog.
	FbxExporterSetParam "Shape" false -- <bool>
	-- Controls the state of the "Shape (Morph modifier)" checkbox in the FBX Export dialog.
	FbxExporterSetParam "Skin" true -- <bool>
	-- Controls the state of the "Skins (Skin Modifier and Physique)" checkbox in the FBX Export dialog.
	FbxExporterSetParam "Animation" true -- <bool>
	-- Controls the state of the "Animation" checkbox in the FBX Export dialog.
	-- FbxExporterSetParam "Resampling" -- <float>
	-- Controls the value of the "Resampling rate (when necessary)" field in the FBX Export dialog.
	FbxExporterSetParam "ShowWarnings" false -- <bool>
	-- Controls the state of the "Show warnings" checkbox in the FBX Export dialog.
	FbxExporterSetParam "EmbedTextures" false -- <bool>
	-- Controls the state of the "Embed textures in export file" checkbox in the FBX Export dialog.
	FbxExporterSetParam "SmoothingGroups" true -- <bool>
	-- True or false. See Smoothing Groups for an explanation of this setting.
	FbxExporterSetParam "SmoothMeshExport" true -- <bool>
	-- True or false. See TurboSmooth for an explanation of this setting.
)

SetupFBX()

g_lastDir1   = ""
g_lastDir2   = ""
g_lastDir3   = ""
g_haveAnim   = true
-- g_lowerBody  = false
-- g_pelvis     = false
-- g_spineName  = "spine_01"
boneNum      = 1
FrameBoneFlag = 0


fn getMultiOpenFilenames caption: "Open" filename: "" types: "All Files (*.*)|*.*" default: 1 =
(
	local dlg = DotNetObject "System.Windows.Forms.OpenFileDialog"
	dlg.multiSelect = true
	dlg.title = caption

	local p = getFilenamePath filename
	if doesFileExist p then
	dlg.initialDirectory = p

	-- MAXScript getOpenFilename uses trailing |;
	-- OpenFileDialog filter does not.
	if types == "|" then
		dlg.filter = (substring types 1 (types.count - 1))
	else
		dlg.filter = types

	dlg.filterIndex = default

	local result = dlg.ShowDialog()
	if (result.Equals result.OK) then
		dlg.filenames
	else
		undefined
)


fn ImportAddAnimFile filename =
(
	append Anims (ReadAnimInfoBinary filename)
)


fn FindAllBones_Recurse bones parent =
(
	for i = 1 to parent.children.count do
	(
		node = parent.children[i]
		if isKindOf node Dummy then
		(
			append bones node
		)
		FindAllBones_Recurse bones node
	)
)


fn FindAllBones =
(
	local bones = #()
	FindAllBones_Recurse bones rootNode
	bones
)


fn ExportAnim filename =
(
	local Dir = getFilenamePath(filename)+"AlterAdditiveAnims"
	makeDir Dir all:true
	local savename =Dir+"\\"+getFilenameFile(filename)
	local Exportname = getFilenameFile(filename)
	local numFrames = animationrange.end
	FBXExporterSetParam "SplitAnimationIntoTakes" "-clear"
	FBXExporterSetParam "SplitAnimationIntoTakes" Exportname 0 numFrames
	exportFile savename #noPrompt using:FBXEXP
)

fn RotationBone X Y Z BoneArray Map BaseAnimBones frame =
(
	local RotationValue = 0
	for a=1 to BoneArray.count do
	(
		case Map of
		(
			1:(RotationValue = BoneArray[a].ValueX)
			2:(RotationValue = BoneArray[a].ValueY)
			3:(RotationValue = BoneArray[a].ValueZ)
			4:(RotationValue = (BoneArray[a].ValueX)*(-1))
			5:(RotationValue = (BoneArray[a].ValueY)*(-1))
			6:(RotationValue = (BoneArray[a].ValueZ)*(-1))
			--default:(RotationValue = BoneRotationArray[a].ValueX)
		)
		
		if AddType==1 then 
		(
			if g_haveAnim then
			(
				animate on at time frame in coordsys world rotate BaseAnimBones[(BoneArray[a].Index)] (EulerAngles (RotationValue*X) (RotationValue*Y) (RotationValue*Z))
			)
			else
			(
				in coordsys world rotate BaseAnimBones[(BoneArray[a].Index)] (EulerAngles (RotationValue*X) (RotationValue*Y) (RotationValue*Z))
			)
		)
		else
		(
			animate on at time frame in coordsys parent rotate BaseAnimBones[(BoneArray[a].Index)] (EulerAngles (RotationValue*X) (RotationValue*Y) (RotationValue*Z))
		) 
	)
)

fn MoveBone BoneArray BaseAnimBones frame = 
(
	local LocationValueX = 0
	local LocationValueY = 0
	local LocationValueZ = 0
	for i=1 to BoneArray.count do
	(
		local LocationValueX =  BoneArray[i].ValueX
		local LocationValueY =  BoneArray[i].ValueY
		local LocationValueZ =  BoneArray[i].ValueZ
		if AddType==1 then
		(
			if g_haveAnim then
			(
				animate on at time frame in coordsys parent move BaseAnimBones[(BoneArray[i].Index)] [LocationValueX,LocationValueY,LocationValueZ]
			)
			else
			(
				in coordsys parent move BaseAnimBones[(BoneArray[i].Index)] [LocationValueX,LocationValueY,LocationValueZ]
			)
		)
		
	)
)


fn CalculateAddRotation index =
(
	importFile Anims[index].Address #noPrompt using:Wavefront_Object
	local bones = FindAllBones()
	local Value_X = 0
	local Value_Y = 0
	local Value_Z = 0
	local Move_X  = 0
	local Move_Y  = 0
	local Move_Z  = 0
	local allFrame = 0
	
	if g_haveAnim then
	(
		--�Ƚ���֡������Ĭ������
		animationRange = interval 0 300
		allFrame = bones[1].rotation.controller.keys.count --��ȡ�ؼ�֡�ĳ���
		--����֡�����ó�Additive Anim�ĳ���
		animationRange = interval 0 allFrame
		FrameBoneRotationArray=#()
		FrameBoneLocationArray=#()
		
		for t=0 to allFrame do
		(
			BoneRotationArray = #()
			BoneLocationArray = #()
			for i=1 to bones.count do
			(
				if i>boneNum then
				(
					Value_X = ((at time t bones[i].rotInParent).x - (at time t bones[i].parent.rotInParent).x)
					Value_Y = ((at time t bones[i].rotInParent).y - (at time t bones[i].parent.rotInParent).y)
					Value_Z = ((at time t bones[i].rotInParent).z - (at time t bones[i].parent.rotInParent).z)
					append BoneRotationArray (SaveValue i bones[i].name Value_X Value_Y Value_Z)
					
					Move_X  = (at time t bones[i].posInParent).x
					Move_Y  = (at time t bones[i].posInParent).y
					Move_Z  = (at time t bones[i].posInParent).z
					append BoneLocationArray (SaveValue i bones[i].name Move_X Move_Y Move_Z)
				)
			)
			append FrameBoneRotationArray BoneRotationArray
			append FrameBoneLocationArray BoneLocationArray
		)
	)
	else
	(
		BoneRotationArray = #()
		BoneLocationArray = #()
		
		for j=1 to bones.count do
		(
			if j>boneNum then
			(
				Value_X = ((at time 0 bones[j].rotInParent).x - (at time 0 bones[j].parent.rotInParent).x)
				Value_Y = ((at time 0 bones[j].rotInParent).y - (at time 0 bones[j].parent.rotInParent).y)
				Value_Z = ((at time 0 bones[j].rotInParent).z - (at time 0 bones[j].parent.rotInParent).z)
				append BoneRotationArray (SaveValue j bones[j].name Value_X Value_Y Value_Z)
				
				--��ȡ������λ��
				Move_X  = (at time 0 bones[j].posInParent).x
				Move_Y  = (at time 0 bones[j].posInParent).y
				Move_Z  = (at time 0 bones[j].posInParent).z
				append BoneLocationArray (SaveValue j bones[j].name Move_X Move_Y Move_Z)
			)
		)
	
	)
	
	--Set Base Animation Rotation
	if DoesFileExist BaseAnimFileName then
	(
		importFile BaseAnimFileName #noPrompt using:Wavefront_Object
		max select all
		macros.run "Animation Tools" "DeleteSelectedAnimation"
		clearSelection()
		local BaseAnimBones = FindAllBones()
		scale BaseAnimBones[1] [(50.0/127.0),(50.0/127.0),(50.0/127.0)]
		
		if g_haveAnim then
		(
			--�����ùؼ�֡
			FrameBoneFlag = 1
			local FrameBones =  FindAllBones()
			FrameBoneFlag = 0
			for t=0 to 	allFrame do
			(
				for i=1 to FrameBones.count do
				(
					animate on at time t move FrameBones[i] [0,0,0]
					animate on at time t scale FrameBones[i] [1,1,1]
					animate on at time t rotate FrameBones[i] (EulerAngles 0 0 0)
				)
			)
			--������������λ��
			for t=0 to allFrame do
			(
				MoveBone FrameBoneLocationArray[t+1] BaseAnimBones t
			)
			
			--��������������ת
			case AixMap of
			(
				1:(
					for t=0 to allFrame do
					(
						RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
						RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
						RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
					)
				)
				2:(
					for t=0 to allFrame do
					(
						RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
						RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
						RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
					)
				)
				3:(
					for t=0 to allFrame do
					(
						RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
						RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
						RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
					)
				)
				4:(
					for t=0 to allFrame do
					(
						RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
						RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
						RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
					)
				)
				5:(
					for t=0 to allFrame do
					(
						RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
						RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
						RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
					)
				)
				6:(
					for t=0 to allFrame do
					(
						RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
						RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
						RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
					)
				)
			)
			
		)
		else
		(
			--MoveBone BoneLocationArray BaseAnimBones 0
			
			case AixMap of
			(
				1:(	RotationBone 1 0 0 BoneRotationArray XMap BaseAnimBones 0
					RotationBone 0 1 0 BoneRotationArray YMap BaseAnimBones 0
					RotationBone 0 0 1 BoneRotationArray ZMap BaseAnimBones 0)
				2:( RotationBone 1 0 0 BoneRotationArray XMap BaseAnimBones 0
					RotationBone 0 0 1 BoneRotationArray ZMap BaseAnimBones 0
					RotationBone 0 1 0 BoneRotationArray YMap BaseAnimBones 0)
				3:( RotationBone 0 1 0 BoneRotationArray YMap BaseAnimBones 0
					RotationBone 1 0 0 BoneRotationArray XMap BaseAnimBones 0
					RotationBone 0 0 1 BoneRotationArray ZMap BaseAnimBones 0)
				4:( RotationBone 0 1 0 BoneRotationArray YMap BaseAnimBones 0
					RotationBone 0 0 1 BoneRotationArray ZMap BaseAnimBones 0
					RotationBone 1 0 0 BoneRotationArray XMap BaseAnimBones 0)
				5:( RotationBone 0 0 1 BoneRotationArray ZMap BaseAnimBones 0
					RotationBone 1 0 0 BoneRotationArray XMap BaseAnimBones 0
					RotationBone 0 1 0 BoneRotationArray YMap BaseAnimBones 0)
				6:( RotationBone 0 0 1 BoneRotationArray ZMap BaseAnimBones 0
					RotationBone 0 1 0 BoneRotationArray YMap BaseAnimBones 0
					RotationBone 1 0 0 BoneRotationArray XMap BaseAnimBones 0)
			)
		)
		
		ExportAnim Anims[index].Address
	)
)
FindAllBonesb
fn GetAddRotation index =
(

	--�Ƚ���֡������Ĭ������
	animationRange = interval 0 300
	
	importFile Anims[index].Address #noPrompt using:Wavefront_Object
	local bones = FindAllBones()
	local allFrame = bones[1].rotation.controller.keys.count --��ȡ�ؼ�֡�ĳ���
	--����֡�����ó�Additive Anim�ĳ���
	animationRange = interval 0 allFrame

	FrameBoneRotationArray=#()
	FrameBoneLocationArray=#()
	
	local Value_X = 0
	local Value_Y = 0
	local Value_Z = 0
	local Move_X  = 0
	local Move_Y  = 0
	local Move_Z  = 0
	for t=0 to allFrame do
	(
		BoneRotationArray = #()
		BoneLocationArray = #()
		
		for j=1 to bones.count do
		(
			if j>boneNum then
			(
				Value_X = (at time t bones[j].rotInParent).x
				Value_Y = (at time t bones[j].rotInParent).y
				Value_Z = (at time t bones[j].rotInParent).z
				append BoneRotationArray (SaveValue j bones[j].name Value_X Value_Y Value_Z)
				
				Move_X  = (at time t bones[j].posInParent).x
				Move_Y  = (at time t bones[j].posInParent).y
				Move_Z  = (at time t bones[j].posInParent).z
				append BoneLocationArray (SaveValue j bones[j].name Move_X Move_Y Move_Z)
			)	
		)
		append FrameBoneRotationArray BoneRotationArray
		append FrameBoneLocationArray BoneLocationArray
	)

	--Set Base Animation Rotation
	if DoesFileExist BaseAnimFileName then
	(
		importFile BaseAnimFileName #noPrompt using:Wavefront_Object
		max select all
		macros.run "Animation Tools" "DeleteSelectedAnimation"
		clearSelection()
		local BaseAnimBones = FindAllBones()
		scale BaseAnimBones[1] [(50.0/127.0),(50.0/127.0),(50.0/127.0)]
		
		--�����ùؼ�֡
		FrameBoneFlag = 1
		local FrameBones =  FindAllBones()
		FrameBoneFlag = 0
		for t=0 to 	allFrame do
		(
			for i=1 to FrameBones.count do
			(
				animate on at time t move FrameBones[i] [0,0,0]
				animate on at time t scale FrameBones[i] [1,1,1]
				animate on at time t rotate FrameBones[i] (EulerAngles 0 0 0)
			)
		)
		
		for t=0 to allFrame do
		(
			MoveBone FrameBoneLocationArray[t+1] BaseAnimBones t
		)
		
		case AixMap of
		(
			1:(
				for t=0 to allFrame do
				(
					RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
					RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
					RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
				)
			)
			2:(
				for t=0 to allFrame do
				(
					RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
					RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
					RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
				)
			)
			3:(
				for t=0 to allFrame do
				(
					RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
					RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
					RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
				)
			)
			4:(
				for t=0 to allFrame do
				(
					RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
					RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
					RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
				)
			)
			5:(
				for t=0 to allFrame do
				(
					RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
					RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
					RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
				)
			)
			6:(
				for t=0 to allFrame do
				(
					RotationBone 0 0 1 FrameBoneRotationArray[t+1] ZMap BaseAnimBones t
					RotationBone 0 1 0 FrameBoneRotationArray[t+1] YMap BaseAnimBones t
					RotationBone 1 0 0 FrameBoneRotationArray[t+1] XMap BaseAnimBones t
				)
			)
		)
		
		ExportAnim Anims[index].Address --��������fbx
	)
)


rollout AdditiveAnimAmend "AdditiveAnimationAmend" width:200 height:700
(
	Group "BaseAnim Import"
	(
		button 'BtnBase' "BaseAnimation" pos:[50,20] width:100 height:30 toolTip:"SelectBaseAnimation" align:#left
	)
	Group "AdditiveAnim Import"
	(
		button 'BtnAdd' "AdditiveAnimation" pos:[50,80] width:100 height:30 toolTip:"SelectAdditiveAnimation" align:#left
		listBox 'LstAnims' "Animations:" pos:[10,115] width:180 height:13 align:#left
		label 'LblX' "X-Axis:" pos:[30,320] width:40 height:22 align:#left
		dropDownList 'DDLX' "" pos:[90,320] width:58 height:22 items:#("X", "Y", "Z", "-X", "-Y", "-Z") selection:1 align:#left
		label 'LblY' "Y-Axis:" pos:[30,350] width:40 height:22 align:#left
		dropDownList 'DDLY' "" pos:[90,350] width:58 height:22 items:#("X", "Y", "Z", "-X", "-Y", "-Z") selection:2 align:#left
		label 'LblZ' "Z-Axis:" pos:[30,380] width:40 height:22 align:#left
		dropDownList 'DDLZ' "" pos:[90,380] width:58 height:22 enabled:true items:#("X", "Y", "Z", "-X", "-Y", "-Z") selection:3 align:#left
		label 'LblAix' "Order:" pos:[30,410] width:40 height:22 align:#left
		dropDownList 'DDLAix' "" pos:[90,410] width:58 height:22 enabled:true items:#("XYZ", "XZY", "YXZ", "YZX", "ZXY", "ZYX") selection:1 align:#left
		label 'LblType' "AdditiveType:" pos:[30,440] width:80 height:22 align:#left
		dropDownList 'DDLType' "" pos:[105,440] width:80 height:22 enabled:true items:#("Mesh Space", "Local Space") selection:1 align:#left
		-- checkbox 'ChkHaveAnim' " With Anim (Mesh Space)" pos:[30,475] width:150 height:20 toolTip:"Whether the pelvis is included" align:#left checked:g_haveAnim
		-- checkbox 'ChkPelvis' " Included Pelvis" pos:[30,505] width:150 height:20 toolTip:"Whether the pelvis is included" align:#left checked:g_pelvis
		-- checkbox 'ChkLowerbody' " Included Lower Body" pos:[30,535] width:150 height:20 toolTip:"Whether the lower body is included" align:#left checked:g_lowerBody
		-- editText 'EdtName' "First Spine Name:" pos:[30,565] width:160 height:20 align:#left text:g_spineName
		button 'BtnExport' "ExportAnimation" pos:[50,475] width:100 height:30 toolTip:"ExportAlterAdditiveAnimation" align:#left
		button 'BtnCFG' "Load Batch Config" pos:[50,525] width:100 height:30 toolTip:"SelectAdditiveAnimation" align:#left
	)
	Group "AdditiveAnim Amend"
	(
		label 'LblAuthor' "@Author:DontWanna404" pos:[30,590] width:150 height:22 align:#left
		label 'LblAuthor2' "Modded by PeterZ" pos:[30,610] width:150 height:22 align:#left
		label 'LblVersion' "@Version:1.3a" pos:[30,630] width:100 height:22 align:#left
	)
	on BtnBase pressed  do
	(
		resetMaxFile #noprompt
		local filename = getOpenFileName types:"Base Animation (*.fbx)|*.fbx|All (*.*)|*.*|" filename:g_lastDir1
		if filename != undefined then
		(
			BaseAnimFileName = filename
			g_lastDir1 = getFilenamePath BaseAnimFileName
			if DoesFileExist BaseAnimFileName then
			(
				importFile BaseAnimFileName #noPrompt using:Wavefront_Object
				local BaseAnimBones = FindAllBones()
				-- scale BaseAnimBones[1] [(50.0/127.0),(50.0/127.0),(50.0/127.0)]
			)
		)
	)
	on BtnAdd pressed  do
	(
		Anims = #()
		if DotNetObject == undefined then
		(
			local filename = getOpenFileName types:"Additive Anim (*.fbx)|*.fbx|All (*.*)|*.*" filename:g_lastDir2
			if filename != undefined then
			(
				AddAnimFileName = filename
				g_lastDir2 = getFilenamePath AddAnimFileName
			)
		)
		else
		(
			local filenames = getMultiOpenFilenames types:"Additive Anim (*.fbx)|*.fbx|All (*.*)|*.*" filename:g_lastDir2
			if filenames != undefined then
			(
				for filename in filenames do
				(
					AddAnimFileName = filename
					g_lastDir2 = getFilenamePath AddAnimFileName
					if DoesFileExist AddAnimFileName then
					(
						ImportAddAnimFile filename
						LstAnims.items = for a in Anims collect (a.Name)
					)
				)
			)
		)
	)
	on BtnCFG pressed  do
	(
		resetMaxFile #noprompt
		if DotNetObject == undefined then
		(
			local filename = getOpenFileName types:"AdditiveCFG (*.cfg)|*.cfg|All (*.*)|*.*" filename:g_lastDir3
			if filename != undefined then
			(
				CfgFileName = filename
				g_lastDir3 = getFilenamePath CfgFileName
			)
		)
		else
		(
			local filenames = getMultiOpenFilenames types:"AdditiveCFG (*.cfg)|*.cfg|All (*.*)|*.*" filename:g_lastDir3
			if filenames != undefined then
			(
				for filename in filenames do
				(
					CfgFileName = filename
					g_lastDir3 = getFilenamePath CfgFileName
					if DoesFileExist CfgFileName then
					(
						local cfgFile = openFile filename
						while eof cfgFile == false do(
							local line = readline cfgFile
							if (line=="") then (
								-- print "skip line"
								continue
							)
							local data = filterString line "|" -- [1] = sequencePath, [2] = refSequencePath, [2] = skelAdditiveSpace
							sequencePath = data[1]
							BaseAnimFileName = data[2]
							skelAdditiveSpace= data[3]
							format "% % %\n" data[1] data[2] data[3]
							-- 导入单个baseanim
							resetMaxFile #noprompt
							importFile BaseAnimFileName #noPrompt using:Wavefront_Object
							local BaseAnimBones = FindAllBones()
							scale BaseAnimBones[1] [(50.0/127.0),(50.0/127.0),(50.0/127.0)]
							-- 导入单个additive动画
							Anims = #()
							ImportAddAnimFile sequencePath
							LstAnims.items = for a in Anims collect (a.Name)
							-- 根据skelAdditiveSpace导出
							XMap = DDLX.selection
							YMap = DDLY.selection
							ZMap = DDLZ.selection
							AixMap = DDLAix.selection
							boneNum = 1
							case skelAdditiveSpace of (
								"1":(AddType = 2)
								"2":(AddType = 1)
							)
							for i=1 to LstAnims.items.count do
							(
								resetMaxFile #noprompt
								case AddType of
								(
									1:(CalculateAddRotation i
									)
									2:(GetAddRotation i
									)
								)
							)
						)
					)
				)
			)
		)
	)
	on BtnExport pressed  do
	(
		BoneRotationArray = #()
		if (LstAnims.items.count>0 and BaseAnimFileName != undefined) then
		(
			XMap = DDLX.selection
			YMap = DDLY.selection
			ZMap = DDLZ.selection
			AixMap = DDLAix.selection
			AddType = DDLType.selection
			-- if g_pelvis then 
			-- (
			-- 	boneNum = 1
			-- )
			-- else boneNum = 2
			boneNum = 1
			for i=1 to LstAnims.items.count do
			(
				resetMaxFile #noprompt
				case AddType of
				(
					1:(CalculateAddRotation i)
					2:(GetAddRotation i)
				)
			)
		)
	)
	
	on ChkHaveAnim changed state do g_haveAnim    = state
	-- on ChkLowerbody changed state do g_lowerBody    = state
	-- on ChkPelvis changed state do g_pelvis    = state
	-- on EdtName      changed val   do g_spineName    = val
	
)CreateDialog AdditiveAnimAmend width:200 height:720
