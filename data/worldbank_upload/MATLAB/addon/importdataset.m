function importdataset(c)
%IMPORTDATASET  this function used to import necessarily data into the data
%    path automatically.
%
%   NOTICE: This function will be triggered after 'wb()' calling. Users can
%   also use this function anytime.

% create a new data folder if necessary.
if exist(c.datapath,'dir') == 0
    fprintf('Folder "%s" is not dectected, generating the data folder... \n',c.datapath);
    mkdir(c.datapath);
end

% Add the following new datasets into the folder.
%   1. country
%   2. topic
%   3. region
%   4. lendingtype
%   5. incomelevel
%   6. indicator
%   7. sources
%   8. Concepts
%   9. ConceptVariables

% import country data
filename = fullfile(c.datapath,'Country.mat');
if exist(filename,'file') == 0
    fprintf('Country data are being downloaded and then imported... ');
    data = country(c);
    data = data{2};
    save(filename, 'data');
    clear data
    fprintf('Done. \n');
end

% import topic data
filename = fullfile(c.datapath,'Topic.mat');
if exist(filename,'file') == 0
    fprintf('Topic data are being downloaded and then imported... ');
    data = topic(c);
    data = data{2};
    save(filename, 'data');
    clear data
    fprintf('Done. \n');
end

% import region data
filename = fullfile(c.datapath,'Region.mat');
if exist(filename,'file') == 0
    fprintf('Region data are being downloaded and then imported... ');
    data = aggregate(c, 'region');
    data = data{2};
    save(filename, 'data');
    clear data
    fprintf('Done. \n');
end

% import income level data
filename = fullfile(c.datapath,'Incomelevel.mat');
if exist(filename,'file') == 0
    fprintf('Income level data are being downloaded and then imported... ');
    data = aggregate(c, 'incomelevel');
    data = data{2};
    save(filename, 'data');
    clear data
    fprintf('Done. \n');
end

% import lending type data
filename = fullfile(c.datapath,'Lendingtype.mat');
if exist(filename,'file') == 0
    fprintf('Lending type data are being downloaded and then imported... ');
    data = aggregate(c, 'lendingtype');
    data = data{2};
    save(filename, 'data');
    clear data
    fprintf('Done. \n');
end

% import indicators data
filename = fullfile(c.datapath,'Indicators.mat');
if exist(filename,'file') == 0
    fprintf('Indicator data are being downloaded and then imported... ');
    data = [];
    p    = 1;
    while 1
        data_tmp = indicator(c, [], 'page', num2str(p) );
        if isempty(data_tmp{2})
            break
        end
        data = [data; data_tmp{2}];%#ok
        p = p + 1;
    end
    save(filename, 'data');
    clear data data_tmp p
    fprintf('Done. \n');
end

% import source data
filename = fullfile(c.datapath,'Sources.mat');
if exist(filename,'file') == 0
    fprintf('Source data are being downloaded and then imported... ');
    data = getSources(c);
    data = data{2};
    save(filename, 'data');
    clear data
    fprintf('Done. \n');
end

% import concepts data

% if source data exists, then load data.
s = fullfile(c.datapath,'Sources.mat');
if exist(s,'file') ~= 0
    data = getfield(load(s), 'data' );
end

id = {data.id};
filename = fullfile(c.datapath,'Concepts.mat');
if exist(filename,'file') == 0
    fprintf('Concept data are being downloaded and then imported... ');
    data = [];
    for n = 1:length(id)
        data_tmp = getConcepts(c,id{n});
        data = [data; data_tmp.source];%#ok
    end
    save(filename, 'data');
    fprintf('Done. \n');
end

% import concept variables data

% if concept data exists, then load data.
s = fullfile(c.datapath,'Concepts.mat');
if exist(s,'file') ~= 0
    data = getfield(load(s), 'data' );
end

filename = fullfile(c.datapath,'ConceptVariables.mat');
if exist(filename,'file') == 0
    fprintf('Concept variables data are being downloaded and then imported... ');
    for n = 1:length(data)
        data_tmp = [];
        for m = 1:length({data(n).concept.id})
            try
                x = getConceptVariables(c, data(n).id, data(n).concept(m).id, 'all');
                data_tmp = [data_tmp; x.source.concept];%#ok
            catch
            end
        end
        data(n).concept_variable = data_tmp;
    end
    save(filename, 'data');
    clear data data_tmp x m n s
    fprintf('Done. \n');
end