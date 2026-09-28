function [time_qualityFiltered, filteredFrfX_qualityFiltered, filteredFrfY_qualityFiltered, filteredHeight_NAVD88_qualityFiltered, qualityFlagged]=qualityFlagFiltering(Sig0_qual, interferogramQual, geolocationQual, time, filteredFrfX, filteredFrfY, filteredHeight_NAVD88, landClass);
    qualityFlagged=zeros(length(Sig0_qual),1);
      
    % Logical indexing to flag quality issues
    qualityFlagged = (Sig0_qual >= 33554432) | ...
        (interferogramQual >= 134217728) | ...
        (geolocationQual == 4) | ...
        (geolocationQual >= 134217728) | ...
        (landClass <= 2);
    
      % for i=1:length(Sig0_qual)
        %     if (Sig0_qual(i)  >= 33554432 || interferogramQual(i)  >= 134217728 || geolocationQual(i) == 4 || geolocationQual(i) >= 134217728 || landClass <= 2)  % Filters using geolocation 
        %         qualityFlagged(i)=1;
        %     end
        % end
      % qualityFlagged=logical(qualityFlagged);
    
    time_qualityFiltered=time(qualityFlagged~=1);
    filteredFrfX_qualityFiltered=filteredFrfX(qualityFlagged~=1);
    filteredFrfY_qualityFiltered=filteredFrfY(qualityFlagged~=1);
    filteredHeight_NAVD88_qualityFiltered=filteredHeight_NAVD88(qualityFlagged~=1);
end