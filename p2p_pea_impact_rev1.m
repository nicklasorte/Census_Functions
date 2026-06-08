function p2p_pea_impact_rev1(app,array_p2p_Alatlon,array_p2p_Blatlon,pea_label,preA_clean,preB_clean,pre_tree_label)

retry_load=1;
while(retry_load==1)
    try
        %%%%%%%%%%load('cell_pea_census_data.mat','cell_pea_census_data')
        load('cell_pea_census_data_2020_2023.mat','cell_pea_census_data_2020')%%%%%%%%Using the 2023 Census Tracts) %%%%%PEA Name, PEA Num, PEA {Lat/Lon}, PEA Pop, PEA Centroid, Census {Geo ID},Census{Population},Census{NLCD}, Census Centroid
        cell_pea_census_data=cell_pea_census_data_2020;
        pause(0.1)
        retry_load=0;
    catch
        retry_load=1
        pause(1)
    end
end

[num_pea,~]=size(cell_pea_census_data)
cell_pea_inside_idx=cell(num_pea,2);  %%%1) A, 2)B
ab_link=cell(num_pea,2);
tic;
for pea_idx=1:1:num_pea
    temp_pea_bound=cell_pea_census_data{pea_idx,3};
    [insideA_idx]=find_points_inside_contour_two_step(app,temp_pea_bound,array_p2p_Alatlon);
    cell_pea_inside_idx{pea_idx,1}=insideA_idx;
    ab_link{pea_idx,1}=preA_clean(insideA_idx);
    [insideB_idx]=find_points_inside_contour_two_step(app,temp_pea_bound,array_p2p_Blatlon);
    cell_pea_inside_idx{pea_idx,2}=insideB_idx;
    ab_link{pea_idx,2}=preB_clean(insideB_idx);
end
toc;  %%%%1 seconds

cellsz=cell2mat(cellfun(@size,cell_pea_inside_idx,'uni',false));
pea_count_data=cellsz(:,1)+cellsz(:,3);
sum(pea_count_data)
pea_heatmap_graph_rev2(app,pea_count_data,pea_label)  %%%%%%%%This is the PEA Plot


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%Now create the table of links per agency per agency
%%%%%%%%%%%%%%%%%%%%%%%
uni_agency=unique(preA_clean)
n_rows = size(ab_link, 1);
n_agencies = numel(uni_agency);
agency_counts = zeros(n_rows,n_agencies);
for row = 1:n_rows
    % Combine both columns for this row
    combined = [ab_link{row,1}; ab_link{row,2}];
    
    % Count each agency
    for k = 1:n_agencies
        agency_counts(row, k) = ceil(sum(strcmp(combined, uni_agency{k}))/2);
    end
end
sum_count=sum(agency_counts,2);
sum(sum_count)
agency_table=array2table(agency_counts, 'VariableNames', uni_agency);
pea_agency_count=horzcat(cell2table(cell_pea_census_data_2020(:,[1,2])),array2table(sum_count),agency_table);
pea_agency_count.Properties.VariableNames{'Var1'} = 'PEA';
pea_agency_count.Properties.VariableNames{'Var2'} = 'PEA_ID';
pea_agency_count.Properties.VariableNames{'sum_count'} = 'Total_Links';
pea_agency_count
writetable(pea_agency_count, strcat(pea_label,'_pea_agency_count.xlsx'), 'Sheet', 'Agency Counts');


%%%%%%%%%Sort it by number of links
[~,sort_idx]=sort(sum_count,'descend');
sort_pea_agency_count=pea_agency_count(sort_idx,:)
writetable(sort_pea_agency_count,strcat(pre_tree_label,'_sort_pea_agency_count.xlsx'), 'Sheet', 'Agency Counts');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%Make the square tree map for number of links per agency'

[uni_agency,~,c_idx] = unique(preA_clean);
[count_ag,edges]=histcounts(c_idx,unique(c_idx),'Normalization', 'probability');
[sort_count_ag,sort_idx]=sort(count_ag,'descend');
agency_rectangles = treemap_topleft(sort_count_ag);
color_set=flipud(plasma(length(uni_agency)));
sort_uni_agency=uni_agency(sort_idx)

%%%%%%%%%%%%%%%%%%%%%%%Labels with Percentages
num_ag=length(sort_count_ag);
cell_ag_per=cell(num_ag,1);
for i=1:1:num_ag
    temp_str=sort_uni_agency{i} + "\n" + strcat(num2str(round(sort_count_ag(i)*100)),'%');
    cell_ag_per{i}=compose(temp_str);
end

f1=figure;
hold on;
plotRectangles(agency_rectangles,cell_ag_per,color_set)
outline(agency_rectangles)
title('P2P')
f1.Position
f1.Position = [100 100 600 600];
pause(1)
filename1=strcat(pre_tree_label,'_TreeMap_P2P_StudyLinks.png');
pause(0.1)
saveas(gcf,char(filename1))
pause(0.1)
%close(f1)
end