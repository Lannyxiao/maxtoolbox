global MouseClicking = false
global WindowPos = [0,0]
global QAProjectConfigPath = (getdir #userscripts) + "\QAProjectConfig.ini"
global QAToolbox
fn destroyAllDialog = 
(
	try (destroydialog QAToolbox) catch()
	try (cui.unRegisterDialogBar QAProjectConfig) catch()
	try (destroydialog QAProjectConfig) catch()
	try (cui.unRegisterDialogBar QAToolbox_Model) catch()
	try (destroydialog QAToolbox_Model) catch()
	try (cui.unRegisterDialogBar QAToolbox_UV) catch()
	try (destroydialog QAToolbox_UV) catch()
	try (cui.unRegisterDialogBar QAToolbox_Material) catch()
	try (destroydialog QAToolbox_Material) catch()
	try (cui.unRegisterDialogBar SmoothGroupChecker) catch()
	try (destroydialog SmoothGroupChecker) catch()
	try (cui.unRegisterDialogBar AddConfig) catch()
	try (destroydialog AddConfig) catch()
	try (cui.unRegisterDialogBar cleanupPolyRange) catch()
	try (destroydialog cleanupPolyRange) catch()
	try (cui.unRegisterDialogBar rollout_uvoutofrange) catch()
	try (destroydialog rollout_uvoutofrange) catch()
	try (cui.unRegisterDialogBar rollout_densityCheck) catch()
	try (destroydialog rollout_densityCheck) catch()
	try (cui.unRegisterDialogBar rollout_nameCheck) catch()
	try (destroydialog rollout_nameCheck) catch()
	try (cui.unRegisterDialogBar rollout_weldCheck) catch()
	try (destroydialog rollout_weldCheck) catch()
	try (cui.unRegisterDialogBar QAToolbox_namingCheck) catch()
	try (destroydialog QAToolbox_namingCheck) catch()
)
destroyAllDialog()

--functions start here
fn getEditablePolyObjs objs=
(
	if objs == undefined do 
	(
		ifSelectAll = queryBox "什么都没选, 是否要全选?"
		if ifSelectAll == true then
		(
			objs = $*
		)else return #()
	)
	ifValid = true
	message = ""
	invalidObjs = #()
	validObjs = #()
	for obj in objs do
	(
		if classof obj != Editable_Poly then
		(
			try
			(
				polyop.getNumEdges obj
				append validObjs obj
			)catch
			(
				if classof obj != Targetobject and classof obj != Biped_Object and classof obj != Dummy and classof obj != Targetcamera and classof obj != Freecamera then
				(
					ifValid = false
					message += obj.name + "是" + (classof obj as string) + ",不是Editable_Poly,"
					append invalidObjs obj
				)
			)
			
		)else append validObjs obj
	)
	if(ifValid == false) then
	(

		message += "是否要尝试转换为Editable_Poly?		\n"
		ifConvertToPoly = queryBox message
		if(ifConvertToPoly == true) then
		(
			for obj in invalidObjs do
			(
				try(
					polyop.getNumEdges $
				)catch
				(
					if canConvertTo obj Editable_Poly then
					(
						convertTo obj Editable_Poly
						append validObjs obj
					)
				)
			)
		)
	)
	validObjs
)

function getMaxVersion =
(
    local maxvArr = maxversion()
    local maxvi = maxvArr[1]
    local maxv = "2014"
    if (maxvi >= 8000 and maxvi < 9000) then maxv = "8"
    else if (maxvi >= 9000 and maxvi < 10000) then maxv = "9"
    else if (maxvi >= 10000 and maxvi < 11000) then maxv = "2008"
    else if (maxvi >= 11000 and maxvi < 12000) then maxv = "2009"
    else if (maxvi >= 12000 and maxvi < 13000) then maxv = "2010"
    else if (maxvi >= 13000 and maxvi < 14000) then maxv = "2011"
    else if (maxvi >= 14000 and maxvi < 14900) then maxv = "2012"
    else if (maxvi >= 14900 and maxvi < 16000) then maxv = "2013"
    else if (maxvi >= 16000 and maxvi < 17000) then maxv = "2014"
    else if (maxvi >= 17000 and maxvi < 18000) then maxv = "2015"
    else if (maxvi >= 18000 and maxvi < 19000) then maxv = "2016"
    else if (maxvi >= 19000 and maxvi < 20000) then maxv = "2017"
    else if (maxvi >= 20000 and maxvi < 21000) then maxv = "2018"
    else if (maxvi >= 21000 and maxvi < 22000) then maxv = "2019"
    return maxv
)
fn fileversion =
(
    message = ""
    if fileProperties.getItems "General" != undefined then 
        (
            general = fileProperties.getItems "General"
            version_tokenize = filterString general[1] " "
            version = version_tokenize[4] as integer
            if version == 9 then (
                message = "此文件版本：max 9"
            )else (
                message = "此文件版本：max" + ((version + 1998) as string)
            ) 
        )
    else if fileProperties.getItems "常规" != undefined then
        (
            general = fileProperties.getItems "常规"
            version_tokenize = filterString general[1] " "
            version = version_tokenize[4] as integer
            if version == 9 then (
                message = "此文件版本：max 9"
            )else (
                message = "此文件版本：max" + ((version + 1998) as string)
            ) 
        )
    else 
        (
            message = "未检测到文件版本！   \n" + "请注意：此功能只适用中文简体或英文版max保存的文件！  \n"
        )
	messagebox message 
)

function isEditablePoly node=
(
	if (classof node) == Editable_Poly then
	(
		return true
	)
	return false
)
function ifEditableMesh node=
(
	if (classof node) == Editable_Mesh then
	(
		return true
	)
	return false
)

function getSmoothGroupsCount node=
(
	faceCount = getNumFaces node
	groups = #()
	for face = 1 to faceCount do
	(
		num = polyop.getFaceSmoothGroup node face
		if(num != 0) do
		(
			append groups num
		)
	)
	newGroup = #()
	for g in groups do
	(
		if(findItem newGroup g) == 0 do
		(
			append newGroup g
		)
	)
	return newGroup.count
)

--polyop
function checkSmoothGroupCount obj countLimit=
(
	message = ""
	polyop.getNumEdges obj
	smoothGroupCount = getSmoothGroupsCount obj
	message = obj.name + ": 共有"
	message += (smoothGroupCount as string)
	message += "组"
	if(smoothGroupCount > countLimit) then
	(
		message += ", 数量超限!!!"
	)
	return message
)

--polyop
function ifHasNoSmoothGroup node &facesWithoutSmoothGroup=
(
	faceCount = getNumFaces node
	for face = 1 to faceCount do
	(
		num = polyop.getFaceSmoothGroup node face
		if(num == 0) do
		(
			append facesWithoutSmoothGroup face
		)
	)
)

function smoothGroupCheck nodes limit=
(
	message = ""
	-- if checkIfValid nodes
	objs = getEditablePolyObjs nodes
	for obj in objs do
	(
		facesWithoutGroup = #()
		startCount = facesWithoutGroup.count
		message += (checkSmoothGroupCount obj limit)
		ifHasNoSmoothGroup obj &facesWithoutGroup
		endCount = facesWithoutGroup.count
		if(endCount - startCount != 0) then
		(
			message += ", 包含没有光滑组的面.		\n"
			polyop.setfaceselection obj facesWithoutGroup
			try(subobjectlevel = 4) catch()
		)
		else
		(
			if(message != "") do message += ".	\n"
		)
	)
	if message != "" then
	(
		messagebox message
	)
)

function selectOpenedges nodes ifBatch:false=
(
	message = ""
	objs = getEditablePolyObjs nodes
	ifhas = false
    for obj in objs do
    (
		openEdge = polyop.getOpenEdges obj --get open edges
		openEdge = openEdge as array
		if (openEdge.count != 0) then
		(
			ifhas = true
			message += obj.name + " 有开放边."
			polyop.setEdgeSelection obj openEdge --select the open edges
			message += "        \n"
		)
	)
	if ifhas == true then message += "请进入边级别查看!		\n"
	else if not ifBatch then
	(
		message = "没有开放边!"
	)
    return message
)

function selectNgons objs =
(
	message = ""
	objs = getEditablePolyObjs objs
    for obj in objs do (
		faceCount = getNumFaces obj
		groups = #()
		for face = 1 to faceCount do (
			verts = polyop.getFaceVerts obj face
			if(verts != undefined)then
			(
				vertsCount = verts.count
				if (vertsCount > 4) then
				(
					append groups face
				) 
			)
		) 
		if (groups.count != 0) then
			message += obj.name + "有多边面！请在面级别查看！        \n"
		polyop.setFaceSelection obj groups
    )
    return message
)

function HidenObjCheck objs ifBatch:false=
(
	objs = $*
	message=""
	ifHidden = false
	hiddenObj = #()
    for sel in (for obj in objs where (((getPolygonCount obj)[2] == 0) and ((superclassof obj) == GeometryClass)) collect obj) do
		(
			ifHidden = true
			message += sel.name + "是空模型!		\n"
			append hiddenobj sel
		)
		if ifHidden then 
		(
			message += "需要清理吗? 	\n"
			if queryBox message then
			(
				delete hiddenObj
			)
		)
	else
		(
			if not ifBatch then
			(
				clearSelection()
				messageBox "没有空模型		\n"
			)
		)
)

function emptyLayers ifBatch:false=
(
	emptyLayerlist = #()
	deflayer = layermanager.getlayer 0
	deflayer.current = true
	message = "有空图层:		\n"
	ifhas = false
	for i = 1 to layerManager.count-1 do
	(
		ilayer = layerManager.getLayer i
		nodes = ilayer.nodes &theNodes
		if ( theNodes.count == 0) do (
			if (ilayer.name != "0") do (
				append emptyLayerlist ilayer.name
				message += ilayer.name + "		\n"
				ifhas = true
			)
		)
	)
	if ifhas then
	(
		message += "是否要删除?		\n"
		if queryBox message then
		(
			for layerName in emptyLayerlist do
			(
				LayerManager.deleteLayerbyname layerName
			)
		)
	)else
	(
		if not ifBatch then
		(
			messageBox "没有空图层.		\n"
		)
	)

	return emptyLayerlist
)

rollout SmoothGroupChecker "光滑组检查" width:180 height:35
(
	spinner groupMaxCount "组数上限:" offset:[25,5] range:[0,32,10] type:#integer across:2
	button btn_checkSmoothGroup "检查" offset:[15,0]  height: 24 ToolTip: "检查光滑组"
	--move 
	on SmoothGroupChecker lbuttonup pos do  
		MouseClicking=false
	on SmoothGroupChecker lbuttondown pos do
	(
		MouseClicking=true
		WindowPos=pos
	)
	on SmoothGroupChecker mouseMove pos do
	(
		if MouseClicking==true Then SetDialogPos SmoothGroupChecker (mouse.screenpos-WindowPos)
	)
	on btn_checkSmoothGroup pressed do
	(
		smoothGroupCheck $ SmoothGroupChecker.groupMaxCount.value
	)
)

--项目管理
fn SaveFileConfig projectName fileName=
(
	fileNames= #()
	try(ReadProjectConfig projectName &fileNames &tempunit &displayUnit)
	catch(fileNames= #())
	if fileNames == undefined then fileNames = #()
	if (classof fileNames) == String then fileNames = execute fileNames
	append fileNames fileName
	options.printallelements = true
	setINISetting QAProjectConfigPath projectName "FileNames" (fileNames as string)
	options.printallelements = false
)
global QAProjectConfig
fn ReadProjectConfig projectName &fileNames &systemUnit &displayUnit=
(
	fileNames = getINISetting QAProjectConfigPath projectName "FileNames"
	systemUnit = getINISetting QAProjectConfigPath projectName "SystemUnit"
	displayUnit = getINISetting QAProjectConfigPath projectName "DisplayUnit"
)
fn RemoveFileConfig projectName fileName=
(
	ReadProjectConfig projectName &fileNames &systemUnit &displayUnit
	fileNames = execute fileNames
	index = findItem fileNames fileName
	if index != 0 then
	(
		deleteItem fileNames index
		options.printallelements = true
		setIniSetting QAProjectConfigPath projectName "FileNames" (fileNames as string)
		options.printallelements = false
	)
)

fn updateProjectConfigs =
(
	currentFileName = getFilenameFile maxfilename
	QAProjectConfig.systemUnitLabel.text = "当前系统单位: " + units.SystemType
	QAProjectConfig.displayUnitLabel.text = "当前显示单位: " + units.DisplayType
	QAProjectConfig.lbl_filename.text = "当前文件: " + currentFileName
	projects = getINISetting QAProjectConfigPath
	QAProjectConfig.projectList.items = projects
	projectBelonged = ""
	systemUnit = ""
	displayUnit = ""
	for project in projects do
	(
		ReadProjectConfig project &fileNames &systemUnit &displayUnit
		if(filenames != undefined)then
		(
			filenames = execute filenames
			index = findItem filenames currentFileName
			if index != 0 do
			(
				projectBelonged = project
			)
		)
	)
	if(projectBelonged=="") then
	(
		QAProjectConfig.projectSystemUnitLabel.text = "系统单位: "
		QAProjectConfig.projectDisplayUnitLabel.text = "显示单位: "
		QAProjectConfig.lbl_projectname.text = "所属项目: "
	)else
	(
		QAProjectConfig.lbl_projectname.text = "所属项目: " + projectBelonged
		projectSystemUnitLabel = "系统单位: " + systemUnit
		QAProjectConfig.projectSystemUnitLabel.text = projectSystemUnitLabel
		(
			if(units.SystemType != execute ("#"+ systemUnit)) then
			QAProjectConfig.systemUnitLabel.text =  "当前系统单位: " + units.SystemType + "(不匹配, 请修改后刷新)"
		)
		projectDisplayUnitLabel = "显示单位: " + displayUnit
		QAProjectConfig.projectDisplayUnitLabel.text = projectDisplayUnitLabel
		(
			if(units.DisplayType != execute ("#"+ displayUnit)) then
			QAProjectConfig.displayUnitLabel.text =  "当前显示单位: " + units.DisplayType + "(不匹配, 请修改后刷新)"
		)
	)

	if QAProjectConfig.projectList.selected != undefined then
	(	
		ReadProjectConfig QAProjectConfig.projectList.selected &filenames &tempunit &tempunit2
		if filenames != undefined then 
		(
			QAProjectConfig.fileList.items = execute filenames
		)
		else QAProjectConfig.fileList.items = #()
	)else
	(
		QAProjectConfig.fileList.items = #()
	)
)

fn SaveProjectConfig projectName systemUnit displayUnit=
(
	ifHas = hasINISetting QAProjectConfigPath projectName
	if not ifHas then
	(
		setINISetting QAProjectConfigPath projectName "FileNames" "#()"
		setINISetting QAProjectConfigPath projectName "SystemUnit" systemUnit
		setINISetting QAProjectConfigPath projectName "DisplayUnit" displayUnit
	)else
		messageBox "已存在"
	updateProjectConfigs()
)

rollout AddConfig "添加项目"
(
	edittext projectname "项目名称"
	dropdownlist systemUnit "系统单位:" items:#("Millimeters", "Centimeters","Meters","Kilometers","Inches","Feet","Miles") selection:2 tooltip:"单位"
	dropdownlist displayUnit "显示单位:" items:#("Millimeters", "Centimeters","Meters","Kilometers") selection:2 tooltip:"单位"
	button addProject "添加" 
	on addProject pressed do
	(
		SaveProjectConfig projectname.text systemUnit.selected  displayUnit.selected
		DestroyDialog AddConfig
		updateProjectConfigs()
	)
)

rollout QAProjectConfig "QA项目管理器" width:500 height:280
(
	button refresh "刷新" width:148 offset:[0,5] across:2 align:#left 
	button openConfig "打开配置文件路径" width:305 offset:[-78,5] align:#left Tooltip:"QAProjectConfig.ini"
	label projectSystemUnitLabel "系统单位:" across:2 align:#left
	label systemUnitLabel "当前系统单位:" align:#left offset:[-78,0]
	label projectDisplayUnitLabel "显示单位:" across:2 align:#left 
	label displayUnitLabel "当前显示单位:" align:#left offset:[-78,0]
	label lbl_projectname "当前项目: " across:2 align:#left
	label lbl_filename "当前文件: " align:#left offset:[-78,0]
	listbox projectList "项目目录:" items:#("Test1","Test2") selection:1 width:148 across:2
	multilistbox fileList "文件(可多选):" items:#("请先选择项目!","") width:305 offset:[-78,0]
	button addProject "添加项目" width:70 across:6 align:#left
	button removeProject "移除项目" width:70 align:#left
	button batchAddFile "添加文件夹" width:70 align:#left
	button addFile "添加当前" width:70 align:#left
	button selectCurrent "选中当前" width:70 align:#left
	button removeFile "移除选中" width:70 align:#left
	on QAProjectConfig open do
	(
		updateProjectConfigs()
		callbacks.addscript #filePostOpen "updateProjectConfigs()" id:#QAProjectConfigUpdate
	)
	on refresh pressed do
	(
		-- print updateProjectConfigs()
		-- units.SystemType = (execute "#"+unit)
		updateProjectConfigs()
	)
	on addProject pressed do
	(
		CreateDialog AddConfig pos:(mouse.screenpos + [60,-60])
	)
	on openConfig pressed do
	(
		command = "explorer " + (getdir #userscripts)
		HiddenDOSCommand command
	)
	on removeProject pressed do
	(
		projectName = projectList.selected
		if(projectName != undefined) then
		(
			ifRemove = queryBox "确定要移除整个项目吗?"
			if ifRemove do delIniSetting QAProjectConfigPath projectName
			updateProjectConfigs()
		)else messageBox "请先选择一个项目!"
	)
	on projectList selected index do
	(
		updateProjectConfigs()
	)
	on batchAddFile pressed do
	(			
		folderName = getSavePath caption:"Select Folder"
		if folderName != null then
		(
			print folderName+"\\.max"

			allFiles = getFiles(folderName+"\\*.max")
			for file in allfiles do
			(
				afileName = getFilenameFile file
				projectName = QAProjectConfig.projectList.selected
				SaveFileConfig projectName afileName
				print afileName
			)
			updateProjectConfigs()
		)
	)
	on addFile pressed do
	(
		projectName = QAProjectConfig.projectList.selected
		currentFileName = getFilenameFile maxfilename
		if currentFileName == "" then
		(
			messageBox "当前文件名为空!"
		)
		else
		(
			SaveFileConfig projectName currentFileName
			updateProjectConfigs()
		)
	)
	on selectCurrent pressed do
	(
		projects = getINISetting QAProjectConfigPath
		projectBelonged = ""
		currentFileName = getFilenameFile maxfilename
		for project in projects do
		(
			ReadProjectConfig project &fileNames &unit
			if(filenames != undefined)then
			(
				filenames = execute filenames
				index = findItem filenames currentFileName
				if index != 0 do
				(
					projectBelonged = project
				)
			)
		)
		projectIndex = -1
		for index=1 to QAProjectConfig.projectList.items.count do
		(
			if projectBelonged == QAProjectConfig.projectList.items[index] then
			(
				projectindex = index
				break
			)
		)
		if projectIndex != -1 then
		(
			QAProjectConfig.projectList.selection = projectIndex
			updateProjectConfigs()
			currentFileNames = QAProjectConfig.fileList.items
			for fileIndex=1 to currentFileNames.count do
			(
				file = currentFileNames[fileIndex]
				currentFile = getFilenameFile maxfilename
				if(currentFile == file)then
				(
					QAProjectConfig.fileList.selection = #{fileIndex}
				)
			)
		)else messageBox "当前文件不属于任何项目!		\n"
		
	)
	on removeFile pressed do
	(
		projectName = QAProjectConfig.projectList.selected
		currentFileNames = QAProjectConfig.fileList.selection
		for fileIndex in currentFileNames do
		(
			file = QAProjectConfig.fileList.items[fileIndex]
			RemoveFileConfig projectName file
		)
		updateProjectConfigs()
	)
	on QAProjectConfig close do(
		QAToolbox.btn_projectConfig.state = false
		try (cui.unRegisterDialogBar AddConfig) catch()
		try (destroydialog AddConfig) catch()
	)
)
fn checkProject = 
(
	projects = getINISetting QAProjectConfigPath
	projectBelonged = ""
	currentFileName = getFilenameFile maxfilename
	for project in projects do
	(
		ReadProjectConfig project &fileNames &unit &displayUnit
		if(filenames != undefined)then
		(
			filenames = execute filenames
			index = findItem filenames currentFileName
			if index != 0 do
			(
				projectBelonged = project
			)
		)
	)
	if projectBelonged == "" then
	(
		messageBox "项目中找不到当前文件!		\n"
	)else
	(
		message = "属于 " + projectBelonged + " 项目.		\n"
		if(units.SystemType != execute ("#"+ unit))then
		(
			message += "当前单位 "+(units.SystemType as string)+ " 项目单位 "+unit+" 不匹配!		\n"
		)else
		(
			message += "单位匹配.	\n"
		)
		messageBox message
	)

)
fn checkTransform =
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0
	)
	obj = selection[1]
	message = ""
	if obj.pos != [0,0,0] or obj.rotation != quat 0 0 0 1 or obj.scale !=[1,1,1] then
	(
		if (queryBox "Transform (坐标,旋转,缩放) 不标准, 是否冻结?		\n") then obj.pivot = [0,0,0]
		else if (queryBox "Transform (坐标,旋转,缩放) 不标准, 是否重置?		\n") do obj.transform = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
	)else
	(
		messagebox "Transoform OK		\n"
	)
	if(queryBox "是否重置XForm?		\n") then
	(
        ResetXForm obj
        collapseStack obj
	)
)
fn cleanupVertEdge ifBatch:false=
(
	objs = getEditablePolyObjs $
	if objs == #() do return 0
	message = ""
	invalidObjs = #()
	ifhas = false
	
	--游离点
	for obj in objs do
	(
		numVerts = polyop.getNumVerts obj
		polyop.setVertSelection obj #all
		polyop.deleteIsoVerts obj
		if (polyop.getNumVerts obj) != numVerts do
		(
			message += obj.name + "有游离点		\n"
			ifhas = true
			append invalidObjs obj
		)
	)
	--游离线
	for obj in objs do
	(
		arrFaceAndPoint = getPolygonCount obj
		if arrFaceAndPoint[1] == 0 or arrFaceAndPoint[2] == 0	then 
		(
			message += obj.name +"有游离线		\n"
			ifhas = true
			append invalidObjs obj
		)
	)
	--三面共线
	for obj in objs do
	(
		numEdges = polyop.getnumedges obj
		for i=1 to numedges do
		(
			faces = polyop.getEdgeFaces obj i 
			if faces.count >= 3 then
			(
				message += obj.name +"有三面共线		\n"
				ifhas = true
				append invalidObjs obj
			)
		)
	)
	newInvalidObjs = #()
	for obj in invalidObjs do
	(
		if(findItem newInvalidObjs obj) == 0 do
		(
			append newInvalidObjs obj
		)
	)
	if queryBox "是否清理问题点线? 选否为仅选择		\n" then
	(
		if ifhas then
		(
			for obj in newInvalidObjs do
			(
				delete obj
			)
			message += "点线清理完毕!			\n\n"
			messageBox message
		)
		else
		(
			if not ifBatch then
			(
				clearSelection()
				messageBox "点线OK."
			)
		)
	)else 
	(
		if ifhas then
		(
			messageBox message
			if not ifBatch then
			(
				select newInvalidObjs
			)else
			(
				messageBox "批量模式无法选择		\n"
			)
		)
	)
)
fn checkNormalState ifBatch:false=
(
	objs = getEditablePolyObjs $ 
	if objs == #() do return 0
	message = ""
	invalidObjs = #()
	ifhas = false
	for obj in objs do
	(
		addModifier obj (Edit_Normals()) before:0
		count = 0
		select obj
		numNormals = obj.edit_Normals.EditNormalsMod.GetNumNormals()
		for i =1 to numNormals do
		(
			if (obj.edit_Normals.GetNormalExplicit(i) ) do count+=1
		)
		deleteModifier obj 1
		if count >0 then
		(
			ifhas = true
			message += obj.name +"的法线有锁定,请在点级别下查看		\n"
			append invalidObjs obj
		)
	)
	if ifhas then 
	(
		message += "是否要重置? 需要Collapse!!		\n"
		if(queryBox message)then
		(
			for obj in invalidObjs do
			(
				addModifier obj (Edit_Normals()) before:0
				select obj
				numNormals = obj.edit_Normals.EditNormalsMod.GetNumNormals()
				obj.edit_normals.Reset selection:#{1..numNormals}
				collapseStack obj
			)
			messageBox "重置完毕!"
		)
	)else 
	(
		if not ifBatch then
		(
			clearSelection()
			messageBox "法线OK."
		)
	)
)
function symmetryCheck =
(
	objs = getEditablePolyObjs $ 
	if objs == #() do return 0
	message = ""
	ifnotsymmetry = false

	pos = Point3 0 0 0
	for obj in objs do
	(
		num_vert = obj.GetNumVertices()
		v_coords = for vID = 1 to num_vert collect polyOp.getVert obj vID
		for v in v_coords do
		(
			pos += v
		)
	)

	if pos.x != 0 then 
	(
		ifnotsymmetry = true
		message += "x轴"
	)
	if pos.y != 0 then
	(
		ifnotsymmetry = true
		message += "y轴"
	)
	if pos.z != 0 then
	(
		ifnotsymmetry = true
		message += "z轴"
	)
	if ifnotsymmetry then
	(
		message += "不对称!		\n"
	)else message = "该模型对称.	\n"
	messageBox message
)

function keysCameraLightsCheck ifBatch:false=
(
	ifkey = false
    objs = $*    
	keymessage = ""
	for o in objs do 
    (
		ifposkey = false
		ifrotkey = false
		ifscalekey = false
		try(
			p = o.position.controller.keys.count
			ifposkey = (p!=0)
		)catch()
		try(
			r = o.rotation.controller.keys.count
			ifrotkey = (r!=0)
		)catch()
		try(
			s = o.scale.controller.keys.count
			ifscalekey = (s!=0)
		)catch()

        if (ifposkey or ifrotkey or ifscalekey) then 
        (
			keymessage += o.name + "有K帧!		\n"
			ifkey = true
        )else 
        (
			if not ifBatch then
			(
				keymessage = "没有K帧!		\n"
			)
        )
	)
	if ifkey then
	(
		messageBox keymessage
	)
	if ifkey == true and (queryBox "是否删除关键帧?		\n") then
	(
		deleteKeys objects #allKeys
	)
	--camera
	ifcamera = false
    if cameras.count == 0 then(
		if not ifBatch then
		(
			messageBox "没有摄像机!		\n"
		)
    )else 
    (
		ifcamera = true
        messageBox "有摄像机!		\n"
	)
	if ifcamera == true and (queryBox "是否删除摄像机?		\n") then
	(
		delete cameras 
	)
	--lights
	iflights = false
    if lights.count == 0 then(
		if not ifBatch then
		(
			messageBox "没有灯光!		\n"
		)
    )else 
    (
		messageBox "有灯光!		\n"
		iflights = true
	)
	if iflights == true and (queryBox "是否删除灯光?		\n") then
	(
		delete lights 
	)
)

fn backfaceCulling ifBatch:false=
(
	objs = getEditablePolyObjs $ 
	if objs == #() do return 0
	message = ""
	invalidObjs = #()
	ifhas = false
	for obj in objs do
	(
		if obj.backfaceCull == false then
		(
			message += obj.name + "有双面显示!		\n"
			append invalidObjs obj
			ifhas = true
		)
	)
	if ifhas then
	(
		message += "是否关闭双面显示?		\n"
		select invalidObjs
		if queryBox message then
		(
			for obj in invalidObjs do
			(
				obj.backfaceCull = true
			)
		)
	)else 
	(
		if not ifBatch then
		(
			clearSelection()
			messageBox "没有双面显示.		\n"	
		)
	)
)
rollout cleanupPolyRange "QA工具箱-清理面" width:300
(
	spinner range "重叠距离 ( * 0.0001):" range:[1,1000000,1] type:#float across:2 offset:[50,3]
	button confirm "确定" align:#right width:80
	on confirm pressed do 
	(
		therange = range.value * 0.0001
		cleanupPoly therange
	)
)
fn cleanupPoly range =
(
	objs = getEditablePolyObjs $ 
	if objs == #() do return 0
	message = ""
	invalidObjs = #()
	ifhas = false

	for obj in objs do
	(
		ifObjhas = false
		numfaces = polyop.getnumfaces obj
		ifIgnore = #()
		invalidFaces = #()
		for faceA=1 to numfaces do
		(
			append ifIgnore faceA
			centerA = polyop.getFaceCenter obj faceA
			for faceB=1 to numfaces do
			(
				index = findItem ifIgnore faceB
				if index != 0 do continue
				centerB = polyop.getFaceCenter obj faceB
				if ((length (centerA - centerB)) < range) do
				(
					append invalidObjs obj
					append invalidFaces faceA
					append invalidFaces faceB
					ifObjhas = true
					ifhas = true
				)
			)
		)
		newInvalidFaces = #()
		for face in invalidFaces do
		(
			if(findItem newInvalidFaces face) == 0 do
			(
				append newInvalidFaces face
			)
		)
		if(ifObjhas) do message += obj.name + "有重叠面		\n"
		polyop.setFaceSelection obj newInvalidFaces
	)
	if ifhas then
	(
		messageBox message
		select invalidObjs
	)else
	(
		clearSelection()
		messageBox "OK."
	)
)
fn nameCheck prefix baseName suffix=
(
	if prefix == "" and baseName == "" and suffix == "" then
		(
			messageBox "没有指定查询字符!		\n"
			return 0
		)
	if $ == undefined do (
		messageBox "请选择至少一个物体!		\n"
		return 0
	)
	message = ""
    wrongobjs = #()
	for obj in $ do
	(
		myname = obj.name
		if prefix != "" then
		(
			prefixs = filterString prefix " "
			ifHas = false
            for p in prefixs do (
				matchString = p + "*"
				matched = matchPattern obj.name pattern:matchString ignorecase:false
				if not matched then
				(
					ifHas = true
				)
			)
			if(ifHas)then
			(
                message += obj.name + " 前缀不对 "
                append wrongobjs obj
			)
		)
		if(baseName != "")then
		(
			baseNames = filterString baseName " "
			ifHas = false
            for p in baseNames do (
				matchString = "*"+ p + "*"
				matched = matchPattern obj.name pattern:matchString ignorecase:false
				if not matched then
				(
					ifHas = true
				)
			)
			if(ifHas)then
			(
                message += obj.name + " 基础名不对 "
                append wrongobjs obj
			)		
		)
		if suffix != "" then
		(
			suffixs = filterString suffix " "
			ifHas = false
            for s in suffixs do (
				matchString = "*"+s
				matched = matchPattern obj.name pattern:matchString ignorecase:false
				if not matched then
				(
					ifHas = true
				)
			)   
			if(ifHas)then
			(
				message += obj.name +  "后缀不对		\n"
				append wrongobjs obj
			)
		) 
	)
    select wrongobjs
	if(message != "") then messageBox message
	else messageBox "一切OK."
)
rollout rollout_nameCheck "QA工具箱-命名检查" width:150
(
	edittext prefix "前缀" 
	edittext baseName "基础名" 
	edittext suffix "后缀"
	button confirm "检查"
	on confirm pressed do
	(
		nameCheck prefix.text baseName.text suffix.text
	)
)
fn vertexColorCheck ifBatch:false=
(
	objs = getEditablePolyObjs $ 
	if objs == #() do return 0
	message = ""
	invalidObjs = #()
	ifhas = false

	for obj in objs do
	(
		try(
		polyop.getNumMapVerts obj 0
			message += obj.name+ "有顶点色		\n"
			ifhas= true
			append invalidObjs obj
		)catch ()
	)

	if ifhas then
	(
		messageBox message
		if queryBox "是否要删除顶点色? 需要塌陷		\n" then
		(
			for obj in invalidObjs do
			(
				ChannelInfo.ClearChannel obj 0
				collapseStack obj
			)
		)
	)else
	(
		if not ifBatch then
		(
			messageBox "都没有顶点色.		\n"
		)
	)
)
fn curveCheck ifBatch:false=
(
	objs = $*
	message = ""
	invalidObjs = #()
	ifhas = false

	for obj in objs do
	(
		if (superclassof obj) == shape then
		(
			append invalidObjs obj
			ifhas = true
			message += obj.name + "是曲线类!		\n"
		)
	)
	if ifhas then
	(
		messageBox message
		if queryBox "是否要删除曲线类物体?		\n" then
		(
			delete invalidObjs
		)
	)else
	(
		if not ifBatch then
		(
			messageBox "场景中不包含曲线.		\n"
		)
	)
)

fn weldCheck therange =
(
	objs = getEditablePolyObjs $ 
	if objs == #() do return 0
	message = ""
	invalidObjs = #()
	
	for obj in objs do
	(
		ifhas = false
		num_vert = obj.GetNumVertices()
		vID_array = #()
		count = 0
		for vID =1 to num_vert do
		(
			count += 1
			append vID_array count
		)

		ifignore = #()
		vertTooClose = #()
		for i = 1 to num_vert do 
		(
			append ifignore i
			for j=1 to num_vert do (
				index = finditem ifignore j
				if (index == 0) then
				(
					d = distance (polyop.getvert obj i) (polyop.getvert obj j)
					if d < therange do
					(
						ifhas = true
						append vertTooClose j
						append vertTooClose i
					)
				)
			) 
		)
		newvertTooClose = #()
		for vert in vertTooClose do
		(
			if(findItem newvertTooClose vert) == 0 do
			(
				append newvertTooClose vert
			)
		)
		if ifhas then
		(
			if queryBox (obj.name + "有"+ (vertTooClose.count as string) + "个顶点需要焊接, 是否焊接?		\n") then
			(
				obj.weldThreshold = therange
				polyop.weldVertsByThreshold obj vertTooClose	
			)
		)else
		(
			--messageBox "不需要焊接. 	\n"
		)
	)
)
rollout rollout_weldCheck "QA工具箱-顶点距离" width:300
(
	spinner range "顶点距离 ( * 0.0001):" range:[1,1000000,1] type:#float across:2 offset:[50,3]
	button confirm "确定" align:#right width:80
	on confirm pressed do 
	(
		therange = range.value * 0.0001
		weldCheck therange
	)
)
fn parentChildCheck ifBatch:false=
(
	objs = $*
	if $ != undefined then
	(
		objs = $
	)
	if objs == undefined do
	(
		messageBox "请先选择!		\n"
	)
	message = ""
	ifhas = false
	for obj in objs do
	(
		ifobjhas = false
		aline = obj.name
		if obj.children.count != 0 do
		(
			ifhas = true
			ifobjhas = true
			aline +=  "有"+ (obj.children.count as string) +"个子级!"
		)
		if obj.parent != undefined do
		(
			ifhas = true
			ifobjhas = true
			aline += "有父级-" + obj.parent.name
		)
		aline += "		\n"
		if ifobjhas then
		(
			message += aline
		)
	)
	if ifhas then
	(
		messageBox message
	)else if not ifBatch then
	(
		messageBox "没有父子级!	\n"
	)	
)
fn orientationCheck ifBatch:false=
(
	print 1;
	objs = $*
	if $ != undefined then
	(
		objs = $
	)

	message = ""
	ifhas = false
	invalidObjs = #()
	for obj in objs do
	(
		if (obj.dir != [0,0,1]) then
		(
			message += obj.name + "local坐标轴和世界不匹配!		\n"
			ifhas = true
			append invalidObjs obj
		)
	)
	if ifhas then
	(
		messageBox (message + "		\n")
		if(queryBox "是否要用XForm归正?		\n")then
		(
			for obj in invalidObjs do
			(
				ResetXForm obj
			)
		)
	)else 
		if not ifBatch then
		(
			messageBox "local坐标轴正确.		\n"
		)
)
rollout QAToolbox_Model "QA工具箱-模型检查" width:390 height:240
(
	button 		btn_selectAll "勾选全部" 	across:3  width: 100 height:24 offset:[-5,5]
	button 		btn_selectNone "全部取消" 	width: 100 height:24 offset:[-5,5]
	button 		btn_onepunch "一键检查" width: 100 height:24 offset:[-5,5]
	button 		btn_projectCheck "命名单位" width: 63  height:24 across:8  offset:[10,10]
	checkbox    cb_projectCheck ""  width: 10  height:10 offset:[25555,15] 
	button 		btn_orientationCheck "朝向" 	width: 63 height:24 toolTip:"Y轴朝向是否匹配Max Front" offset:[10,10]
	checkbox    cb_orientationCheck ""  width: 10  height:10 offset:[20,15] checked:true
	button 		btn_hiddenCheck "空模型" 	width: 63 height:24 toolTip:"空的模型检查" offset:[5,10]
	checkbox    cb_hiddenCheck ""  width: 10  height:10 offset:[22,15] checked:true
	button 		btn_EmptyLayerCheck "空图层" 	width: 63 height:24 offset:[5,10]
	checkbox    cb_EmptyLayerCheck ""  width: 10  height:10 offset:[22,15] checked:true
	button 		btn_cleanupVertEdge "清理点线" 	width: 63 height:24 toolTip:"游离点,线,三面共线" across:8 offset:[10,10]
	checkbox    cb_cleanupVertEdge ""  width: 10  height:10 offset:[20,15] checked:true
	button 		btn_ngonsCheck "多边面" 	width: 63 height:24 toolTip:"多边面数检查" offset:[4,10]
	checkbox    cb_ngonsCheck ""  width: 10  height:10 offset:[20,15] checked:true
	button 		btn_weldCheck "顶点距离" 	width: 63 height:24 toolTip:"是否顶点过近" offset:[10,10]
	checkbox    cb_versionCheck6 ""  width: 10  height:10 offset:[25555,15]
	button 		btn_normalCheck "法线检查" width: 63  height:24 offset:[10,10]
	checkbox    cb_normalCheck ""  width: 10  height:10 offset:[22,15] checked:true
	button 		btn_smoothGroupCheck "光滑组" width: 63  height:24 across:8 offset:[4,10]
	checkbox    cb_versionCheck8 ""  width: 10  height:10 offset:[25555,15]
	button 		btn_cleanupPoly "重叠面" 	width: 63 height:24 toolTip:"面距离太近" offset:[4,10]
	checkbox    cb_versionCheck9 ""  width: 10  height:10 offset:[25555,15]
	button 		btn_vertexColorCheck "查顶点色" 	width: 63 height:24 toolTip:"是否有顶点色" offset:[10,10]
	checkbox    cb_vertexColorCheck ""  width: 10  height:10 offset:[22,15]checked:true
	button 		btn_symmetryCheck "对称检查" 	width: 63 height:24 offset:[10,10]
	checkbox    cb_symmetryCheck ""  width: 10  height:10 offset:[25555,15]
	button 		btn_nameCheck "命名检查" 	width: 63 height:24 toolTip:"输入多个前缀（或后缀）时，请使用空格隔开!" across:8 offset:[10,10]
	checkbox    cb_nameCheck ""  width: 10  height:10 offset:[25555,15]
	button 		btn_keysCameraLightsCheck "清理帧" 	width: 63 height:24 toolTip:"动作帧, 摄像机 ,灯光" offset:[4,10]
	checkbox    cb_keysCameraLightsCheck ""  width: 10  height:10 offset:[20,15] checked:true
	button 		btn_curveCheck "有无曲线" 	width: 63 height:24 toolTip:"是否有曲线"  offset:[10,10]
	checkbox    cb_curveCheck ""  width: 10  height:10 offset:[22,15] checked:true
	button 		btn_backfaceCulling "双面显示" 	width: 63 height:24 offset:[10,10]
	checkbox    cb_backfaceCulling ""  width: 10  height:10 offset:[22,15] checked:true
	button 		btn_resetTransform "重置坐标" width: 63 height:24  across:8 offset:[10,10]
	checkbox    cb_resetTransform ""  width: 10  height:10 offset:[25555,15]
	button 		btn_openEdgeCheck "开放边" 	width: 63 height:24 offset:[4,10]
	checkbox    cb_openEdgeCheck ""  width: 10  height:10 offset:[20,15] checked:true
	button 		btn_parentChildCheck "父子检查" 	width: 63 height:24 toolTip:" 是否有父子级" offset:[10,10]
	checkbox    cb_parentChildCheck ""  width: 10  height:10 offset:[22,15] checked:true
	button 		btn_versionCheck "版本"  width: 63  height:24 toolTip:"文件的版本检查" offset:[10,10]
	checkbox    cb_versionCheck ""  width: 10  height:10 offset:[25555,15]

	on btn_selectAll pressed do
	(
		cb_orientationCheck.checked = true;
		cb_hiddenCheck.checked = true;
		cb_EmptyLayerCheck.checked = true;
		cb_cleanupVertEdge.checked = true;
		cb_ngonsCheck.checked = true;
		cb_normalCheck.checked = true;
		cb_vertexColorCheck.checked = true;
		cb_keysCameraLightsCheck.checked = true;
		cb_curveCheck.checked = true;
		cb_backfaceCulling.checked = true;
		cb_openEdgeCheck.checked = true;
		cb_parentChildCheck.checked = true;
	)
	on btn_selectNone pressed do
	(
		cb_orientationCheck.checked = false;
		cb_hiddenCheck.checked = false;
		cb_EmptyLayerCheck.checked = false;
		cb_cleanupVertEdge.checked = false;
		cb_ngonsCheck.checked = false;
		cb_normalCheck.checked = false;
		cb_vertexColorCheck.checked = false;
		cb_keysCameraLightsCheck.checked = false;
		cb_curveCheck.checked = false;
		cb_backfaceCulling.checked = false;
		cb_openEdgeCheck.checked = false;
		cb_parentChildCheck.checked = false;
	)
	on btn_onepunch pressed do
	(
		if queryBox "批处理有风险, 请记得先保存, 是否继续?		\n" then 
		(
			if(cb_orientationCheck.state == true) then 
			(
				orientationCheck ifBatch:true
			)
			if(cb_hiddenCheck.state == true) then 
			(
				HidenObjCheck $* ifBatch:true
			)
			if(cb_EmptyLayerCheck.state == true) then 
			(
				emptyLayers ifBatch:true
			)
			if(cb_cleanupVertEdge.state == true) then 
			(
				cleanupVertEdge ifBatch:true
			)
			if(cb_ngonsCheck.state == true) then 
			(
				message = selectNgons $
				if message != "" then
				(
					messageBox message
				)
			)
			if(cb_normalCheck.state == true) then 
			(
				checkNormalState ifBatch:true
			)
			if(cb_vertexColorCheck.state == true) then 
			(
				vertexColorCheck ifBatch:true
			)
			if(cb_keysCameraLightsCheck.state == true) then 
			(
				keysCameraLightsCheck ifBatch:true
			)
			if(cb_curveCheck.state == true) then 
			(
				curveCheck ifBatch:true
			)
			if(cb_backfaceCulling.state == true) then 
			(
				backfaceCulling ifBatch:true
			)
			if(cb_openEdgeCheck.state == true) then 
			(
				message = selectOpenedges $ ifBatch:true
				ifHasOpenEdge = false
				if message == "" then
					ifHasOpenEdge = true
				else
				(
					message += "    "
					messagebox message
				)
			)
			if(cb_parentChildCheck.state == true) then 
			(
				parentChildCheck ifBatch:true
			)
		)
	)
	on btn_versionCheck pressed do
	(
		fileversion()
	)
	on btn_projectCheck pressed do
	(
		checkProject()
	)
	on btn_smoothGroupCheck pressed do
	(
		createdialog SmoothGroupChecker  pos:(mouse.screenpos + [60,-60])
	)
	on btn_openEdgeCheck pressed do 
	(
		message = selectOpenedges $
		message += "    "
		messagebox message
	) 
	on btn_ngonsCheck pressed do
	(
		message = selectNgons $
		if message == "" then
		(
			messagebox "没有多边面！"
		)else 
		(
			messageBox message
		)
	)
	on btn_hiddenCheck pressed do
	(
		message = HidenObjCheck $*
	)
	on btn_cleanupVertEdge pressed do
	(
		cleanupVertEdge()
	)
	on btn_cleanupPoly pressed do
	(
		if queryBox "如果面数过多，运行此功能可能会卡顿，是否继续？      \n" then (
			createDialog cleanupPolyRange
		)
	)
	on btn_EmptyLayerCheck pressed do
	(
		emptyLayers()
	)
	on btn_resetTransform pressed do
	(
		checkTransform()
	)
	on btn_normalCheck pressed do
	(
		checkNormalState()
	)
	on btn_backfaceCulling pressed do
	(
		backfaceCulling()
	)
	on btn_nameCheck pressed do
	(
		createDialog rollout_nameCheck
	)
	on btn_symmetryCheck pressed do
	(
		symmetryCheck()
	)
	on btn_keysCameraLightsCheck pressed do
	(
		keysCameraLightsCheck()
	)
	on btn_vertexColorCheck pressed do
	(
		vertexColorCheck()
	)
	on btn_curveCheck pressed do
	(
		curveCheck()
	)
	on btn_weldCheck pressed do
	(
		createDialog rollout_weldCheck
	)
	on btn_parentChildCheck pressed do
	(
		parentChildCheck()
	)
	on btn_orientationCheck pressed do
	(
		orientationCheck()
	)
	on QAToolbox_Model close do
	(
		QAToolbox.btn_model.state = false
	)
	on QAToolbox_Model open do
	(
		
	)
)
fn checkOutOfRange uvchannel=
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	try(
		uvs = polyop.getNumMapVerts obj uvchannel
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)
	if not polyop.getMapSupport obj uvchannel then
	(
		messageBox "该UV通道不存在"
		return 0
	)
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	uvs = obj.Unwrap_UVW.NumberVertices()
	invalidUVs = #()
	for uv =1 to uvs do
	(
		uvValue = polyop.getMapVert obj uvchannel uv
		if uvValue.x > 1 or uvValue.x < 0  or uvValue.y > 1 or uvValue.y <0 do
		(
			append invalidUVs uv
		)
	)
	obj.Unwrap_UVW.selectVerticesByNode (invalidUVs as bitarray) obj
	if(invalidUVs.count != 0) then
	(
		messageBox "存在超过0-1的UV,请检查!		\n"
		max modify mode
		obj.Unwrap_UVW.edit()
		subObjectLevel =1
	)else
		messageBox "OK.		\n"
)


fn getFaceUVArea obj num = 
(
	refx = 0.0                                                                                                     
	refy = 0.0                                                                                                     
	refwidth = 0.0                                                                                                 
	refheight = 0.0                                                                                                
	refFaceAreaUVW = 0.0                                                                                           
	refFaceAreaGeom = 0.0   
	faces = #{}
	append faces num
	obj.modifiers["Unwrap_UVW"].getArea faces &refx &refy &refwidth &refheight &refFaceAreaUVW &refFaceAreaGeom
	
	refFaceAreaUVW
)

fn checkUVDensity k= 
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	uvchannel = obj.modifiers[1].getMapChannel() + 1
	try(
		uvs = polyop.getNumMapVerts obj uvchannel
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)
	if not polyop.getMapSupport obj uvchannel then
	(
		messageBox "该UV通道不存在"
		return 0
	)

	uvs = obj.Unwrap_UVW.numberPolygons()
	uvDensity = #()
	invalidUvs = #()
	averageDensity = 0
	for i=1 to uvs do
	(
		density = getFaceUVArea obj i
		append uvDensity density
		averageDensity += density
	)
	averageDensity /= uvs
	if k< 1 then
	(
		for i = 1 to uvs do
		(
			if uvDensity[i] < averageDensity * k then
			(
				append invalidUvs i
			)
		)
	)else
	(
		for i = 1 to uvs do
		(
			if uvDensity[i] > averageDensity * k then
			(
				append invalidUvs i
			)
		)
	)
	obj.Unwrap_UVW.selectFacesByNode (invalidUVs as bitarray) obj
	if(invalidUVs.count != 0) then
	(
		messageBox "存在超过密度阈值的UV,请检查!		\n"
		max modify mode
		obj.Unwrap_UVW.edit()
		subObjectLevel =3
	)else
		messageBox "OK.		\n"
)
fn overlapCheck = 
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	uvchannel = obj.modifiers[1].getMapChannel() + 1
	try(
		uvs = polyop.getNumMapVerts obj uvchannel
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)
	if not polyop.getMapSupport obj uvchannel then
	(
		messageBox "该UV通道不存在"
		return 0
	)
	obj.Unwrap_UVW.selectFaces #{}
	subObjectLevel =3
	obj.Unwrap_UVW.selectOverlappedFaces()
	overlapped = obj.Unwrap_UVW.unwrap2.getSelectedFaces()
	obj.Unwrap_UVW.selectFaces overlapped
	if (overlapped as array).count != 0 then
	(
		messageBox "存在重叠的UV!		\n"
		max modify mode
		obj.Unwrap_UVW.edit()
		subObjectLevel =3
	)else messageBox "OK.		\n"
)
fn reverseCheck = 
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	uvchannel = obj.modifiers[1].getMapChannel() + 1
	try(
		uvs = polyop.getNumMapVerts obj uvchannel
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)
	if not polyop.getMapSupport obj uvchannel then
	(
		messageBox "该UV通道不存在"
		return 0
	)
	obj.Unwrap_UVW.selectFaces #{}
	obj.Unwrap_UVW.selectOverlappedFaces()
	obj.Unwrap_UVW.selectInvertedFaces()
	inverted = obj.Unwrap_UVW.unwrap2.getSelectedFaces()
	obj.Unwrap_UVW.selectFaces inverted
	if (inverted as array).count != 0 then
	(
		messageBox "存在翻转的UV!		\n"
		max modify mode
		obj.Unwrap_UVW.edit()
		subObjectLevel =3
	)else messageBox "OK.		\n"
)
fn unwrappedCheck = 
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	uvchannel = obj.modifiers[1].getMapChannel() + 1
	try(
		uvs = polyop.getNumMapVerts obj uvchannel
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)
	if not polyop.getMapSupport obj uvchannel then
	(
		messageBox "该UV通道不存在"
		return 0
	)
	uvs = obj.Unwrap_UVW.numberPolygons()
	invalidUvs = #()
	for i=1 to uvs do
	(
		uvArea = getFaceUVArea obj i
		if(uvArea < 0.00001) then
		(
			append invalidUvs i
		)
	)
	obj.Unwrap_UVW.selectFaces #{}
	obj.Unwrap_UVW.selectFaces (invalidUvs as bitarray)
	if invalidUvs.count != 0 then
	(
		messageBox "存在UV面积小于0.00001的情况, 已选中!		\n"
		max modify mode
		obj.Unwrap_UVW.edit()
		subObjectLevel =3
	)else messageBox "OK.		\n"
)
fn getNumUVChannels = (
	objs = getEditablePolyObjs $
	if objs == #() do return 0
	message = ""
    for obj in objs do (
        count = 0
		for i = 1 to 99 do
		(
			if polyOp.getMapSupport obj i then
			(
				count = i
			)
		)
        if count >= 1 then(
            message += obj.name + "有" + (count as string) + "套uv!		\n"
        )else if count == 0 then
        (
            message += obj.name + "有一套uv.		\n"
		)else 
		(
			message += obj.name + "没有uv!		\n"
		)
	)
	messageBox message
)
fn ifHardEdgeSplit =
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	try(
		uvs = polyop.getNumVerts obj 
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)

	faceCount = polyop.getnumfaces obj
	edgeCount = polyop.getnumedges obj
	groups = #()
	invalidedges = #()
	commonEdges = #{}
	faceIdToEdges = #()
	for i=1 to faceCount do
	(
		append faceIdToEdges -1
	)
	faceIdToGroups = #()
	for i=1 to faceCount do
	(
		append faceIdToGroups -1
	)
	facesAlongHardEdges = #()

	for i=1 to edgeCount do
	(
		faces = polyop.getEdgeFaces obj i
		if faces.count == 2 do
		(
			groupA = polyop.getFaceSmoothGroup obj faces[1]
			groupB = polyop.getFaceSmoothGroup obj faces[2]
			if(groupA != groupB) then
			(
				append facesAlongHardEdges faces[1]
				append facesAlongHardEdges faces[2]
			)
		)
	)

	for i in facesAlongHardEdges do
	(
		groupA = polyop.getFaceSmoothGroup obj i
		faceIdToGroups[i] = groupA
		obj.unwrap_uvw.selectFaces #{i}
		obj.unwrap_uvw.faceToEdgeSelect()
		edges = obj.unwrap_uvw.getselectededges()
		faceIdToEdges[i] = edges
	)
	for i in facesAlongHardEdges do
	(
		for j in facesAlongHardEdges do
		(
			if faceIdToGroups[i] != faceIdToGroups[j] then
			(
				commonEdges = (faceIdToEdges[i] as bitarray * faceIdToEdges[j] as bitarray)
			)
			if commonEdges != undefined then
			(
				commonEdges = commonEdges as array
				if commonEdges.count != 0 then
				(
					append invalidedges commonEdges[1]
				)
			)
		)
	)
	if invalidEdges.count != 0 then
	(
		obj.unwrap_uvw.selectEdges (invalidEdges as bitarray)
		max modify mode
		obj.Unwrap_UVW.edit()
		subObjectLevel = 2
		messageBox "有硬边UV没有断开, 请检查!		\n"
	)else messageBox "OK!"
)

fn bleedCheck = 
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	if Classof obj.modifiers[1] != Unwrap_UVW then
	(
		addModifier obj (Unwrap_UVW()) before:0
	)
	uvchannel = obj.modifiers[1].getMapChannel() + 1
	try(
		uvs = polyop.getNumMapVerts obj uvchannel
	)catch
	(
		messageBox "需要是Editable_Poly!"
		return 0
	)
	if not polyop.getMapSupport obj uvchannel then
	(
		messageBox "该UV通道不存在"
		return 0
	)
	uvValues = #()
	for i = 1 to uvs do
	(
		append uvValues (obj.unwrap_uvw.getVertexPosition 0 i)
	)

)
rollout rollout_densityCheck "QA工具箱-UV密度" width:250
(
	spinner k "uv密度相对倍数" range:[0,10,1] type:#float across:2 offset:[30,3] Tooltip:"大于1的时候会选择高于平均密度, 低于1会选择低于平均密度."
	button confirm "确认" offset:[20,0]
	on confirm pressed do
	(
		checkUVDensity k.value 
	)
)
rollout rollout_uvOutOfRange "QA工具箱-UV超限" width:160
(
	spinner uvChannel "channel" range:[1,8,1] type:#integer across:2 offset:[0,3]
	button confirm "确认" 
	on confirm pressed do
	(
		checkOutOfRange uvChannel.value
	)
)
rollout QAToolbox_UV "QA工具箱-UV检查" width:300 height:90
(
	button 		btn_outOfRange "超过0-1"  width: 63  height:24 toolTip:"是否有UV超过第一象限" across:4  offset:[0,10]
	button 		btn_densityCheck "密度检查" width: 63  height:24 offset:[0,10]
	button 		btn_overlapCheck "选择重叠" width: 63  height:24 offset:[0,10]
	button 		btn_reverseCheck "选择翻转" width: 63  height:24 offset:[0,10]
	button 		btn_getNumUVChannels "套数检查" across:2 width: 63  height:24 offset:[0,10]
	button 		btn_ifHardEdgeSplit "硬边检查" width: 63  height:24 offset:[0,10]
	-- button 		btn_bleedCheck "间距检查" width: 63  height:24 offset:[0,10]
	on btn_outOfRange pressed do
	(
		createDialog rollout_uvOutOfRange
	)
	on btn_densityCheck pressed do
	(
		createDialog rollout_densityCheck
	)
	on btn_overlapCheck pressed do
	(
		overlapCheck()
	)
	on btn_reverseCheck pressed do
	(
		reverseCheck()
	)
	on btn_unwrappedCheck pressed do
	(
		unwrappedCheck()
	)
	on btn_getNumUVChannels pressed do
	(
		getNumUVChannels()
	)
	on btn_ifHardEdgeSplit pressed do
	(
		ifHardEdgeSplit()
	)
	on btn_bleedCheck pressed do
	(
		bleedCheck()
	)
	on QAToolbox_UV close do
	(
		QAToolbox.btn_uv.state = false
	)
)
fn getMaterialIDs obj=
(
	ids = #{}
	m = snapshotasmesh obj
	for f=1 to m.numfaces do ids[getFaceMatID m f] = on
	delete m
	ids
)
fn name_compare_case_insensitive s1 s2 = 
(
	if (lowercase s1.name) < (lowercase s2.name) then return -1
	else if (lowercase s1.name) > (lowercase s2.name) then return 1
	else return 0
)
fn get_scene_materials = 
(
	a = #()
	for i in $* do
	(
		if i.material != undefined then
		(
			if (finditem a i.material) == 0 then append a i.material
		)
	)
	qsort a name_compare_case_insensitive
	return a
)
cm_material = undefined

fn change_mat currentindex =
(
	meditMaterials[currentindex] = Standardmaterial ()
)
fn clearallmats =
(
	for i = 1 to 24 do change_mat i
)
fn clearunused_shift = 
(
	scene_mats = get_scene_materials()
	if scene_mats.count == 0 then clearallmats()
	else
	(
		m = 1   -- Medit last filled slot counter
		for i = 1 to 24 do
		(
			for j = 1 to scene_mats.count do
			(
				if scene_mats[j] == meditMaterials[i] then
				(
					if m != i then   -- if slot != index then copy from index and call clear fcn
					(
						meditMaterials[m] = meditMaterials[i]
						change_mat i
					)
					m += 1  -- either case inc fill slot counter
					exit
				)
				else
				(
					if j == scene_mats.count then change_mat i
					else continue
				)
			)
		)
	)
)
fn checkMaterialId= 
(
	if selection[1] == undefined or selection.count > 1 then
	(
		messageBox "请选择一个物体!		\n"
		return 0	
	)
	obj = selection[1]
	try( 
		ids = getMaterialIDs $
		messageId =""
		for i in ids do
		(
			messageId += " "+ (i	as string)
		)
	)catch(
		messageBox "该对象无法获取材质ID		\n"
		return 0
	)
	matId = #()
	if(obj.mat!=undefined)then
	(
		try(
			for i = 1 to obj.mat.count do
			(
				if obj.mat[i] != undefined then
				(
					append matId i
				)
			)
			matIdBit = matId as bitArray
			matRundant = (matIdBit - ids) as array
			objRundant = (ids - matIdBit) as array
			message = ""
			if(matRundant.count !=0) then
			(
				message += "子材质冗余ID: "
				for i in matRundant do
				(
					message += i as string + "  "
				)
				message += "		\n"
			)
			if (objRundant.count !=0) then
			(
				message += "物体没赋材质ID:	"
				for i in objRundant do 
				(
					message += i as string + "  "
				)
				message += "		\n"
			)
			if(matRundant.count == 0 and objRundant.count == 0) then
			(
				messageBox "材质ID OK.		\n"
			)
			else messageBox message
			for mat in scenematerials do
			(
				nodes = refs.dependentnodes mat 
				if nodes.count == 0 do 
				(
					replaceinstances mat def_material
				)
			)
		)catch(
			message = "该物体没有多重材质	\n"
			if(messageId != "") then
			(
				message += "拥有物体材质ID:		\n"
				message += messageId
			)
			messageBox message
		)
	)else messageBox "该物体没有材质!		\n"
)

fn relativePathCheck =
(
	maps = getClassInstances BitmapTexture
	message = ""
	for map in maps do
	(
		if pathConfig.isAbsolutePath(map.filename) then
		(
			message += map.filename +" 是绝对路径!	\n"
		)
	)
	if message == "" then
	(
		messageBox "都是相对路径.	\n"
	)else messageBox message
)
fn deleteUnusedMateirals =
(
	clearunused_shift()

)
fn texSizeCheck=
(
	maps = #()
	for i in $* do
	(
		join maps (usedMaps i)
	)
	message = ""
	for map in maps do
	(
		bitTex = openBitmap map
		message += map +" 尺寸: "+ (bitTex.width as string)+ " " +(bitTex.height as string)  + "	\n"
	)
	if message == "" then
	(
		messageBox "没有贴图.		\n"
	)else
	(
		messageBox message
	)
)
fn textureFormat =
(
	maps = getClassInstances BitmapTexture
	message = ""
	for map in maps do
	(
		filename = map.filename
		type = getFilenameType filename
		message += filename + " 类型为: " + type
	)
	if message == "" then
	(
		messageBox "没有贴图.		\n"
	)else
	(
		messageBox message
	)
)
fn bitmapChannelCheck=
(
	maps = #()
	for i in $* do
	(
		join maps (usedMaps i)
	)
	message = ""
	for map in maps do
	(
		bitTex = openBitmap map
		map_tokenize = filterString map "\\" 
		map_name = map_tokenize[map_tokenize.count]
		if bitTex.hasAlpha == true then
		(
			message += map_name +" 有Alpha通道"+ "	\n"
		)else(
		    message += map_name +" 没有Alpha通道"+ "	\n"
		)
	)

		messageBox message

)
fn sizeformatchannelCheck =
(
    maps = #()
	for i in $* do
	(
		join maps (usedMaps i)
	)
	message = ""
	for map in maps do
	(
		bitTex = openBitmap map
		map_tokenize = filterString map "\\" 
        map_name = map_tokenize[map_tokenize.count]
        n = filterstring map_name "."
        texname = n[1]
        format = n[n.count]
        if bitTex.hasAlpha == true then
            (
                message += texname + " 尺寸:" + (bitTex.width as string)+ " " +(bitTex.height as string) + " 格式:" + format + " 有Alpha"+ "	\n"
            )else(
                message += texname + " 尺寸:" + (bitTex.width as string)+ " " +(bitTex.height as string) + " 格式:" + format + "	\n"
            )
    )
        messageBox message
)
rollout QAToolbox_Material "QA工具箱-材质贴图" width:300 height:90
(
	button 		btn_checkMaterialId "多余材质"  width: 63  height:24 across:4  offset:[0,10]
	button 		btn_relativePathCheck "相对路径" width: 63  height:24 offset:[0,10]
	button 		btn_clearMaterials "清理无用" width: 63  height:24 offset:[0,10]
	button 		btn_namingCheck "命名检查" 	width: 63 height:24 offset:[0,10]
	button 		btn_sizeformatchannelCheck "贴图信息" 	width: 63 height:24 offset:[0,10] toolTip:"贴图尺寸、格式、通道"across:4
	
	on btn_checkMaterialId pressed do
	(
		checkMaterialId()
	)
	on btn_relativePathCheck pressed do
	(
		relativePathCheck()
	)
	on btn_clearMaterials pressed do
	(
		deleteUnusedMateirals()
	)
	on btn_sizeformatchannelCheck pressed do
	(
		sizeformatchannelCheck()
	)
	on btn_namingCheck pressed do
	(
		CreateDialog QAToolbox_namingCheck
	)
	on QAToolbox_Material close do
	(
		QAToolbox.btn_material.  state = false
	)
)
rollout QAToolbox_namingCheck "QA工具箱-材质贴图" width:250 height:160
(
	label title "查出不满足以下条件的:" across:2
	radiobuttons type labels:#("贴图","材质球") 
	edittext prefix "前缀"
	edittext including "包含"
	edittext excluding "不含"
	edittext suffix "后缀"
	button confirm "确认" width: 100
	on confirm pressed do
	(
		prefixString = prefix.text + "*"
		includingString = "*" + including.text + "*"
		excludingString = "*" + excluding.text + "*"
		suffixString = "*"+ suffix.text
		invalidprefix = #()
		invalidincluding = #()
		invalidexcluding = #()
		invalidsuffix = #()
		if(type.state == 1) then
		(
			maps = getClassInstances BitmapTexture
			for map in maps do
			(
				mapname = (getFilenameFile map.filename)
				if not (matchPattern mapname pattern:prefixString ignoreCase:false) and prefixString!="*" then
				(
					append invalidprefix map.filename
				)
				if not (matchPattern mapname pattern:includingString ignoreCase:false) and includingString!="**" then
				(
					append invalidincluding map.filename
				)
				if (matchPattern mapname pattern:excludingString ignoreCase:false) and excludingString!="**" then
				(
					append invalidexcluding map.filename
				)
				if not (matchPattern mapname pattern:suffixString ignoreCase:false) and suffixstring!="*" then
				(
					append invalidsuffix map.filename
				)
			)
		)else
		(
			for mat in sceneMaterials do
			(
				matname = mat.name
				if not (matchPattern matname pattern:prefixString ignoreCase:false) and prefixString!="*" then
				(
					append invalidprefix matname
				)
				if not (matchPattern matname pattern:includingString ignoreCase:false) and includingString!="**" then
				(
					append invalidincluding matname
				)
				if (matchPattern matname pattern:excludingString ignoreCase:false) and excludingString!="**" then
				(
					append invalidexcluding matname
				)
				if not (matchPattern matname pattern:suffixString ignoreCase:false) and suffixstring!="*" then
				(
					append invalidsuffix matname
				)
			)
		)
		message = ""
		if(invalidprefix.count != 0) then
		(
			message += "前缀与" + prefixstring +"不匹配: 		\n"
			for x in invalidPrefix do
			(
				message += x + "		\n"
			)
		)
		if(invalidincluding.count != 0) then
		(
			message +=	"缺少: " + includingstring + " 		\n"
			for x in invalidincluding do
			(
				message += x + "		\n"
			)
		)
		if(invalidexcluding.count != 0) then
		(
			message += "不应包含: " + excludingstring + " 		\n"
			for x in invalidExcluding do
			(
				message += x + "		\n"
			)
		)
		if(invalidsuffix.count != 0) then
		(
			message += "后缀与" + suffixstring +"不匹配: 		\n"
			for x in invalidSuffix do
			(
				message += x + "		\n"
			)
		)

		if(message != "")then messageBox message
		else messageBox "全部命名正确.		\n"
	)
)
rollout QAToolbox "QA工具箱" width:100 height:130
(
	checkbutton btn_projectConfig "设置" width:55 height:24 across:2  offset:[0,5] 
	button btn_refresh  "R"   width:19 height:24 align:#right tooltip:"刷新" offset:[3,5] 
	checkbutton btn_model    "模型" 	 width:80  height:24 toolTip:"模型板块" offset:[0,2] 
	checkbutton btn_uv       "UV" 	    offset:[-1,0] width:80  height:24 toolTip:"UV板块" 
	checkbutton btn_material "材质" 	 	 width:80  height:24 toolTip:"贴图板块"

	-- 点击移动
	on QAToolbox lbuttonup pos do  
		MouseClicking=false
	on QAToolbox lbuttondown pos do
	(
		MouseClicking=true
		WindowPos=pos
	)
	on QAToolbox mouseMove pos do
	(
		if MouseClicking==true Then SetDialogPos QAToolbox (mouse.screenpos-WindowPos+[0,-25])
	)
	on btn_refresh pressed do(
		filePath = getThisScriptFilename()
		fileIn filePath
	)
	on btn_model changed state do(
		if state then
		(
			CreateDialog QAToolbox_Model pos:(mouse.screenpos + [60,-60])
		)
		else
		(
			try (cui.unRegisterDialogBar QAToolbox_Model) catch()
			try (destroydialog QAToolbox_Model) catch()
		)
	)
	on btn_uv changed state do(
		if state then
		(
			CreateDialog QAToolbox_UV pos:(mouse.screenpos + [60,-60])
		)
		else
		(
			try (cui.unRegisterDialogBar QAToolbox_UV) catch()
			try (destroydialog QAToolbox_UV) catch()
		)
	)
	on btn_material changed state do(
		if state then
		(
			CreateDialog QAToolbox_Material pos:(mouse.screenpos + [60,-60])
		)
		else
		(
			try (cui.unRegisterDialogBar QAToolbox_Material) catch()
			try (destroydialog QAToolbox_Material) catch()
		)
	)
	on btn_projectConfig changed state do
	(
		if state then
		(
			CreateDialog QAProjectConfig pos:(mouse.screenpos + [60,-60])
		)else
		(
			try (destroydialog QAProjectConfig) catch()
		)
	)

)
createdialog QAToolbox  pos:(mouse.screenpos + [-80,-40]) 

