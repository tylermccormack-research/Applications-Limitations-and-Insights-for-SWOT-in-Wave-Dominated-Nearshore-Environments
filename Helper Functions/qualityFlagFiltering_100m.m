function [time_qualityFiltered, filteredFrfX_qualityFiltered, filteredFrfY_qualityFiltered, filteredHeight_NAVD88_qualityFiltered, qualityFlagged]=qualityFlagFiltering_100m(wseQualFlag, time, filteredFrfX, filteredFrfY, filteredHeight_NAVD88);
    qualityFlagged=zeros(length(wseQualFlag),1);
        for i=1:length(wseQualFlag)
             if wseQualFlag(i) >= 3
                 qualityFlagged(i)=1;
            end
        end
    
    qualityFlagged=logical(qualityFlagged);
    
    time_qualityFiltered=time(qualityFlagged~=1);
    filteredFrfX_qualityFiltered=filteredFrfX(qualityFlagged~=1);
    filteredFrfY_qualityFiltered=filteredFrfY(qualityFlagged~=1);
    filteredHeight_NAVD88_qualityFiltered=filteredHeight_NAVD88(qualityFlagged~=1);
end