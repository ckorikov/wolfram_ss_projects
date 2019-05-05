(* ::Package:: *)

(* Generate List of Wolfram Summer School Projects *)
(*-------- Parameters -------- *)
$urlBase="https://education.wolfram.com/summer/school/alumni/";
$yearFrom=2003;
$yearTo=If[Length@$ScriptCommandLine>1,ToExpression@$ScriptCommandLine[[2]],First@DateList[]-1];
$fileReadme="README.md";
$fileDataset="dataset_wolfram_ss.json";
$textHeader="
# Wolfram Summer School Projects

This page contains the list of projects of
the [Wolfram Summer School](https://education.wolfram.com/summer/school/). To renew this list, please launch the following script.
```bash
wolframscript -file ./parser.wl
```
Also, the list is available as [a dataset in JSON]("<>$fileDataset<>").
";
(*-------- Functions --------- *)
getUrl[year_,name_:""]:=$urlBase<>ToString[year]<>"/"<>name;
parsePageToStudentList[year_Integer, page_]:={year,#}&/@Cases[
	First[#,{}]&@Cases[page, XMLElement["div",{"class"->_?(StringContainsQ["alumni-list"])},__],\[Infinity]],
	XMLElement["li",{},{XMLElement["a",{"shape"->"rect","href"->url_String},{_}]}]-> url,
	\[Infinity]];
parseStudentName[page_]:=Cases[page,XMLElement["h1",{"class"->"name"},{name_String}]-> name,\[Infinity]]//First[#,"Unknown"]&;
parseStudentPhoto[page_, url_String]:=url<>First[Cases[page,XMLElement["img",{"src"->src__,"alt"->__},{}]-> src,\[Infinity]],""];
parseStudentBlockProject[page_]:=Cases[page,XMLElement["div",{"class"->_?(StringContainsQ["alumni-copy"])},__],\[Infinity]]//First[#,"Unknown"]&;
parseStudentProject[page_]:=Cases[getStudentBlockProject[page],XMLElement["h2",{},x__]:>x,\[Infinity]]/.XMLElement[__,__,t__]:>t//Flatten[#,\[Infinity]]&//StringJoin//StringCases[#,"Project: "~~x__:>x]&//First[#,"Unknown"]&;
processStudentListToData[students_List]:=(WriteString["stdout","."]; With[{x=#},{First@x,getUrl@@x,parseStudentName@#,parseStudentProject@#,parseStudentPhoto[#,getUrl@@x]}&@Import[getUrl@@x,"XMLObject"]])& /@ students;
generateDatasetRow[data_List]:=(WriteString["stdout","."]; With[{img=Import[Last@data]},Join[<|"Year"->data[[1]],"Photo"->img, "Url"->data[[2]], "Name"->data[[3]], "Project"->data[[4]], "PhotoLink"->data[[5]]|>, First[FacialFeatures[img,{"Gender","Age"}],<||>]]]);
generateMarkdownLine[data_List]:="* [**"<>data[[4]]<>"** "<>data[[3]]<>"]("<>data[[2]]<>")";
(*-------- List ------------- *)
WriteString["stdout", "Fetching student list: "]
pageStudentsPerYear = (WriteString["stdout",#," "]; {#,Import[getUrl[#],"XMLObject"]})& /@ Range[$yearFrom,$yearTo];
WriteString["stdout", "\nFetching project data for each student"]
listStudentsPerYear = parsePageToStudentList@@# & /@ pageStudentsPerYear;
listDataStudentsPerYear = processStudentListToData /@ listStudentsPerYear//Quiet;
WriteString["stdout", "\nGenerating markdown list..."]
mdLines=Map[generateMarkdownLine,#]&/@listDataStudentsPerYear;
md=MapThread[Prepend[#2,"## ["<>ToString[#1]<>"]("<>getUrl[#1]<>")"]&, {Range[$yearFrom,$yearTo], mdLines}]//Reverse//Flatten;
Export[$fileReadme,Prepend[md,$textHeader],"Table"];
(*-------- Dataset ---------- *)
WriteString["stdout", "\nExtracting features from photos"]
datasetWithFacialFeatures = Dataset@(generateDatasetRow/@Flatten[listDataStudentsPerYear,1])//Quiet;
WriteString["stdout", "\nGenerating JSON..."]
datasetWithFacialFeatures[All,{"Name","Age","Gender","Project","Url","PhotoLink"}][[-2]]
Export[$fileDataset,datasetWithFacialFeatures[All,{"Name","Age","Gender","Project","Url","PhotoLink"}],"JSON"];
WriteString["stdout", "\nDone.\n"]
