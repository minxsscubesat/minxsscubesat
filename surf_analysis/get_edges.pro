;+
; Name: GET_EDGES
;
; Purpose: From a vector of contiguous channel boundaries return the
;	commonly used quantities for plotting and scaling.
;
; Calling Sequence
;	contiguous_edges = get_edges( [random_values], /contiguous )
;	returns and ordered and vector with unique elements.
; Category:
;	GEN, UTIL, SPECTRA
;
; Input: Edges -if 1d, contiguous channel boundaries, n+1 values for n channels
;               if 2d, 2xn, [lo(i),hi(i)], etc., assumed contiguous for
;		calculating edges_1
;
; Output:
;	Mean - arithmetic mean of boundaries
;       Gmean - geometric mean
;	width - absolute difference between upper and lower edges
;	edges_2 - 2xn array of edges [lo(i), hi(i)], etc.
;       edges_1 - array of n+1 edges of n contiguous channels
;	Keyword Inputs
;	EPSILON - If the absolute relative difference is less than epsilon
;	then two numbers are considered to be equal and a new bin is not required under
;   the contiguous requirement.  If epsilon isn't passed but CONTIGOUS is set it
;	attempts to construct an epsilon based on the average relative difference between
;	adjacent bins, it takes that value and multiplies it by 1e-5 and limits that to
;	1e-6
;   CONTIGUOUS - force all edges to be contiguous, including edges_1
;
; Mod. History:
;
; 8-dec-2001, richard.schwartz@gsfc.nasa.gov, made a function
;	based on edge_products
; 25-aug-2006, ras, added epsilon and default epsilon as test
;	to differentiate real numbers. If the absolute relative difference is less than epsilon
;	then two numbers are considered to be equal and a new bin is not required under
;   the contiguous requirement
;-
function get_edges,edges, mean=mean, gmean=gmean, width=width, $
	edges_2=edges_2, edges_1=edges_1, contiguous=contiguous, epsilon=epsilon

kmean = keyword_set( mean )
kgmean = keyword_set( gmean )
kwidth = keyword_set( width)

k2 = keyword_set( edges_2)
k1 = keyword_set( edges_1)

edge_products, edges, mean=mean, gmean=gmean, width=width, $
	edges_2=edges_2, edges_1=edges_1, contiguous=contiguous, epsilon=epsilon


case 1 of
	keyword_set( kmean): return, mean
	keyword_set(kgmean): return, gmean
	keyword_set(kwidth): return, width
	keyword_set(k2): return, edges_2
	keyword_set(k1): return, edges_1
	keyword_set(contiguous): return, edges_1
	else: return, { mean:mean, gmean:gmean, width:width, edges_2:edges_2, $
							edges_1:edges_1}

	endcase

;It never gets here.
return, 0
end
