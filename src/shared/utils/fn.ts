// src/shared/utils/fn.ts
import _ from "lodash";

interface GetInfoDataParams {
    fields: string[];
    object: Record<string, any>;
}

const getInfoData = ({ fields, object }: GetInfoDataParams): Partial<Record<string, any>> => {
    return _.pick(object, fields);
}
export { getInfoData };