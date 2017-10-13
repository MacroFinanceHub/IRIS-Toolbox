function this = empty(varargin)
% empty  Create empty time series or empty an existing time series
%
% __Syntax__
%
%     x = Series.empty([0, size, ...])
%     x = Series.empty(0, size, ...)
%     x = Series.empty(x)
%
% 
% __Input Arguments__
%
% * `size` [ numeric ] - Size of new time series in 2nd and higher
% dimensions; first dimenstion (time) must be always 0.
%
% * `this` [ Series ] - Input time series that will be emptied.
%
%
% __Output Arguments__
%
% * `this` [ Series ] - Empty time series with first dimension (time) zero.
%
%
% __Description__
%
%
% __Example__
%

% -IRIS Macroeconomic Modeling Toolbox.
% -Copyright (c) 2007-2017 IRIS Solutions Team.

%--------------------------------------------------------------------------

nanDate = DateWrapper(NaN);
if nargin==1 && isa(varargin{1}, 'series.Abstract')
    this = varargin{1};
    this.Start = nanDate;
    newSize = size(this.Data);
    newSize(1) = 0;
    this.Data = double.empty(newSize);
else
    this = Series( );
    newData = double.empty(varargin{:});
    assert( ...
        size(newData, 1)==0, ...
        exception.Base('Series:TimeDimMustBeZero', 'error') ...
    );
    this.Start = nanDate;
    this.Data = newData;
    sizeData = size(newData);
    this.Comment = repmat({''}, [1, sizeData(2:end)]);
end

end