function c = from_cmm_type(type)
    switch type
       case 'R'
          c = 'double';
       case 'I'
          c = 'int32';
       case 'L'
          c = 'int64';
       case 'T'
          c = 'char';
       case 'B'
          c = 'char';
       otherwise
          error(['Could not find class for cmm_type: ' type]);
    end
end


 